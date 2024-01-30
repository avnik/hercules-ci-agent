module Hercules.Agent.Effect where

import Data.Aeson qualified as A
import Data.IORef
import Data.Map qualified as M
import Data.Vector (Vector)
import Hercules.API.Agent.Effect.EffectTask qualified as EffectTask
import Hercules.API.Logs.LogEntry (LogEntry)
import Hercules.API.TaskStatus (TaskStatus)
import Hercules.API.TaskStatus qualified as TaskStatus
import Hercules.Agent.Config qualified as Config
import Hercules.Agent.Env hiding (config)
import Hercules.Agent.Env qualified as Env
import Hercules.Agent.Files
import Hercules.Agent.InitWorkerConfig qualified as InitWorkerConfig
import Hercules.Agent.Log
import Hercules.Agent.Sensitive (Sensitive (Sensitive))
import Hercules.Agent.WorkerProcess
import Hercules.Agent.WorkerProcess qualified as WorkerProcess
import Hercules.Agent.WorkerProtocol.Command qualified as Command
import Hercules.Agent.WorkerProtocol.Command.Effect qualified as Command.Effect
import Hercules.Agent.WorkerProtocol.Event qualified as Event
import Hercules.Agent.WorkerProtocol.ViaJSON (ViaJSON (ViaJSON))
import Hercules.Secrets qualified as Secrets
import Protolude
import System.Posix.Signals qualified as PS
import System.Process

performEffect :: (Vector LogEntry -> IO ()) -> EffectTask.EffectTask -> App TaskStatus
performEffect sendLogEntries effectTask = withWorkDir "effect" $ \workDir -> do
  workerExe <- getWorkerExe
  commandChan <- liftIO newChan
  workerConfig <- InitWorkerConfig.getWorkerConfig
  workerEnv <-
    liftIO $
      WorkerProcess.prepareEnv
        ( WorkerProcess.WorkerEnvSettings
            { nixPath = mempty,
              extraEnv = mempty
            }
        )
  effectResult <- liftIO $ newIORef Nothing
  let procSpec =
        (System.Process.proc workerExe ["effect", toS effectTask.derivationPath])
          { env = Just workerEnv,
            close_fds = True,
            cwd = Just workDir
          }
      writeEvent :: Event.Event -> App ()
      writeEvent event = case event of
        Event.LogItems (ViaJSON e) -> do
          liftIO (sendLogEntries e)
        Event.EffectResult e -> do
          liftIO $ writeIORef effectResult (Just e)
        Event.Exception e -> do
          panic e
        _ -> pass
  config <- asks Env.config
  liftIO $
    writeChan commandChan $
      Just $
        Command.Effect $
          Command.Effect.Effect
            { drvPath = EffectTask.derivationPath effectTask,
              inputDerivationOutputPaths = encodeUtf8 <$> EffectTask.inputDerivationOutputPaths effectTask,
              secretsPath = toS $ Config.secretsJsonPath config,
              serverSecrets = Sensitive $ ViaJSON (EffectTask.serverSecrets effectTask),
              token = Sensitive (EffectTask.token effectTask),
              apiBaseURL = Config.herculesApiBaseURL config,
              projectId = EffectTask.projectId effectTask,
              projectPath = EffectTask.projectPath effectTask,
              secretContext =
                Secrets.SecretContext
                  { ownerName = EffectTask.ownerName effectTask,
                    repoName = EffectTask.repoName effectTask,
                    ref = EffectTask.ref effectTask,
                    isDefaultBranch = EffectTask.isDefaultBranch effectTask
                  },
              configuredMountables = Sensitive (ViaJSON (Config.effectMountables config))
            }
  let stderrHandler =
        stderrLineHandler
          sendLogEntries
          ( M.fromList
              [ ("taskId", A.toJSON (EffectTask.id effectTask)),
                ("derivationPath", A.toJSON (EffectTask.derivationPath effectTask))
              ]
          )
          "Effect worker"
  exitCode <- runWorker workerConfig procSpec stderrHandler commandChan writeEvent
  logLocM DebugS $ "Worker exit: " <> logStr (show exitCode :: Text)
  let showSig n | n == PS.sigABRT = " (Aborted)"
      showSig n | n == PS.sigBUS = " (Bus)"
      showSig n | n == PS.sigCHLD = " (Child)"
      showSig n | n == PS.sigFPE = " (Floating point exception)"
      showSig n | n == PS.sigHUP = " (Hangup)"
      showSig n | n == PS.sigILL = " (Illegal instruction)"
      showSig n | n == PS.sigINT = " (Interrupted)"
      showSig n | n == PS.sigKILL = " (Killed)"
      showSig n | n == PS.sigPIPE = " (Broken pipe)"
      showSig n | n == PS.sigQUIT = " (Quit)"
      showSig n | n == PS.sigSEGV = " (Segmentation fault)"
      showSig n | n == PS.sigTERM = " (Terminated)"
      showSig _ = ""
  case exitCode of
    ExitSuccess -> pass
    ExitFailure n -> panic $ "Effect worker failed with exit code " <> show n <> showSig (negate $ fromIntegral n)
  liftIO (readIORef effectResult) >>= \case
    Nothing -> pure $ TaskStatus.Exceptional "Effect worker terminated without reporting status"
    Just 0 -> pure $ TaskStatus.Successful ()
    Just n | n > 0 -> pure $ TaskStatus.Terminated ()
    Just n -> pure $ TaskStatus.Exceptional $ "Effect process exited with status code " <> show n <> showSig (negate $ fromIntegral n)
