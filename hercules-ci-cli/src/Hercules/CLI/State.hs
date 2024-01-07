{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE BlockArguments #-}

module Hercules.CLI.State (commandParser, getProjectAndClient) where

import Conduit (mapC, runConduitRes, sinkFile, stdoutC, (.|))
import Data.Has (Has)
import Hercules.API (ClientAuth, NoContent, enterApiE)
import Hercules.API.Name (Name (Name))
import Hercules.API.State
import Hercules.CLI.Client
import Hercules.CLI.Common (runAuthenticated)
import Hercules.CLI.Options (mkCommand, subparser)
import Hercules.CLI.Project (ProjectPath (projectPathOwner, projectPathProject, projectPathSite), findProjectContextually, projectOption)
import Options.Applicative (auto, bashCompleter, completer, help, long, metavar, option, strOption)
import qualified Options.Applicative as Optparse
import Protolude
import RIO (RIO)
import qualified RIO.ByteString as BS
import Servant.API (Headers (Headers), fromSourceIO, toSourceIO)
import Servant.Client.Generic (AsClientT)
import Servant.Client.Internal.HttpClient.Streaming (ClientM)
import Servant.Conduit ()
import qualified Servant.Types.SourceT as Servant

commandParser, getCommandParser, putCommandParser :: Optparse.Parser (IO ())
commandParser =
  subparser
    ( mkCommand
        "get"
        (Optparse.progDesc "Download a state file")
        getCommandParser
        <> mkCommand
          "put"
          (Optparse.progDesc "Upload a state file")
          putCommandParser
    )
getCommandParser = do
  projectMaybe <- optional projectOption
  name <- nameOption
  file <- fileOption
  versionMaybe <- optional versionOption
  pure do
    runAuthenticated do
      projectStateClient <- getProjectAndClient projectMaybe
      -- TODO: version
      runHerculesClientStream (getStateData projectStateClient name versionMaybe) \case
        Left e -> dieWithHttpError e
        Right (Headers r _) -> do
          runConduitRes $
            fromSourceIO r .| mapC fromRawBytes .| case file of
              "-" -> stdoutC
              _ -> sinkFile file
putCommandParser = do
  projectMaybe <- optional projectOption
  name <- nameOption
  file <- fileOption
  pure do
    runAuthenticated do
      projectStateClient <- getProjectAndClient projectMaybe
      bytes <- case file of
        "-" -> BS.getContents
        _ -> BS.readFile file
      _ :: NoContent <- retryOnFail "state put" do
        putStateData projectStateClient name (Servant.source [RawBytes bytes])
      putErrText $ "hci: State file upload successful for " <> name

nameOption :: Optparse.Parser Text
nameOption = strOption $ long "name" <> metavar "NAME" <> help "Name of the state file"

fileOption :: Optparse.Parser FilePath
fileOption = strOption $ long "file" <> metavar "FILE" <> help "Local path of the state file or - for stdio" <> completer (bashCompleter "file")

versionOption :: Optparse.Parser Int
versionOption = option auto $ long "version" <> metavar "INT" <> help "Version of the state file to retrieve"

getProjectAndClient :: (Has HerculesClientToken r, Has HerculesClientEnv r) => Maybe ProjectPath -> RIO r (ProjectStateResourceGroup ClientAuth (AsClientT ClientM))
getProjectAndClient projectMaybe =
  case projectMaybe of
    Just projectPath ->
      pure (stateClient `enterApiE` \api -> byProjectName api (Name $ projectPathSite projectPath) (Name $ projectPathOwner projectPath) (Name $ projectPathProject projectPath))
    Nothing -> do
      (projectIdMaybe, projectPath) <- findProjectContextually
      case projectIdMaybe of
        Just projectId ->
          pure (stateClient `enterApiE` \api -> byProjectId api projectId)
        Nothing ->
          pure (stateClient `enterApiE` \api -> byProjectName api (Name $ projectPathSite projectPath) (Name $ projectPathOwner projectPath) (Name $ projectPathProject projectPath))
