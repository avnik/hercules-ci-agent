{-# LANGUAGE DataKinds #-}

module Hercules.Agent.Nix.Init where

import Data.Map qualified as M
import Hercules.Agent.Config (Config, Purpose (Final))
import Hercules.Agent.Config qualified
import Hercules.Agent.EnvironmentInfo qualified as EnvironmentInfo
import Hercules.Agent.Nix.Env
import Hercules.CNix qualified as CNix
import Protolude

newEnv :: Config 'Final -> IO Env
newEnv config = do
  for_ (M.toList config.nixSettings) $ \(k, v) -> do
    CNix.setGlobalOption k v
  nixInfo <- EnvironmentInfo.getNixInfo
  when (EnvironmentInfo.nixNarinfoCacheNegativeTTL nixInfo /= 0) $ do
    putErrText
      "\n\
      \We have detected that the Nix setting narinfo-cache-negative-ttl is non-zero.\n\
      \Running hercules-ci-agent on a system with a non-zero negative ttl will cause\n\
      \problems when run in a cluster.\n\
      \Note that this setting only affects the caching of paths that are *missing*\n\
      \from a cache. Paths that *are* in the binary cache are cached as configured in\n\
      \the narinfo-cache-positive-ttl option. You don't need to configure the positive\n\
      \option. \n\
      \\n\
      \On NixOS and nix-darwin, use the recommended installation method via module,\n\
      \make sure that the `narinfo-cache-negative-ttl` isn't set via other means.\n\
      \If you can't use the module, use\
      \    nix.settings.narinfo-cache-negative-ttl = 0;\n\
      \  or\n\
      \    nix.extraOptions = \"narinfo-cache-negative-ttl = 0\"\n\
      \\n\
      \or add to your system /etc/nix/nix.conf:\n\
      \    narinfo-cache-negative-ttl = 0\n\
      \n"
    throwIO $ FatalError "Please configure your system's Nix with:  narinfo-cache-negative-ttl = 0  "
  -- Might want to take stuff from Config and put it in
  -- extraOptions here.
  pure
    Env
      { extraOptions = M.toList config.nixSettings
      }
