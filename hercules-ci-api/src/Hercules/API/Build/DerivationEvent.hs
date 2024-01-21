{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE DuplicateRecordFields #-}

module Hercules.API.Build.DerivationEvent where

import Data.Aeson.Types (FromJSON (..), ToJSON (..), genericParseJSON, genericToEncoding, genericToJSON)
import Data.OpenApi qualified as O3
import Hercules.API.Accounts.SimpleAccount (SimpleAccount)
import Hercules.API.Build.DerivationEvent.BuiltOutput
import Hercules.API.Prelude
import Hercules.API.Projects.SimpleJob (SimpleJob)

data DerivationEvent
  = Queued DerivationEventQueued
  | DependencyFailed DerivationEventDependencyFailed
  | Started DerivationEventStarted
  | Reset DerivationEventReset
  | Failed DerivationEventFailed
  | Succeeded DerivationEventSucceeded
  | Cancelled DerivationEventCancelled
  | ForceCancelled DerivationEventForceCancelled
  | Built DerivationEventBuilt
  | HasCancelled DerivationEventHasCancelled
  | HasCancelledForReset DerivationEventHasCancelledForReset
  deriving (Generic, Show, Eq, NFData, ToSchema)

instance FromJSON DerivationEvent where
  parseJSON = genericParseJSON schemaCompatibleOptions

instance ToJSON DerivationEvent where
  toJSON = genericToJSON schemaCompatibleOptions

  toEncoding = genericToEncoding schemaCompatibleOptions

eventTime :: DerivationEvent -> UTCTime
eventTime (Queued (DerivationEventQueued {time = t})) = t
eventTime (DependencyFailed (DerivationEventDependencyFailed {time = t})) = t
eventTime (Started (DerivationEventStarted {time = t})) = t
eventTime (Reset (DerivationEventReset {time = t})) = t
eventTime (Failed (DerivationEventFailed {time = t})) = t
eventTime (Succeeded (DerivationEventSucceeded {time = t})) = t
eventTime (Cancelled (DerivationEventCancelled {time = t})) = t
eventTime (ForceCancelled (DerivationEventForceCancelled {time = t})) = t
eventTime (Built (DerivationEventBuilt {time = t})) = t
eventTime (HasCancelled (DerivationEventHasCancelled {time = t})) = t
eventTime (HasCancelledForReset (DerivationEventHasCancelledForReset {time = t})) = t

data DerivationEventQueued = DerivationEventQueued
  { time :: UTCTime,
    requeuedForEvalOfJob :: Maybe SimpleJob,
    requeuedForAgent :: Maybe Text
  }
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)

data DerivationEventDependencyFailed = DerivationEventDependencyFailed
  { time :: UTCTime
  }
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)

data DerivationEventStarted = DerivationEventStarted
  { time :: UTCTime,
    logId :: Id "log",
    agentHostname :: Maybe Text,
    streamable :: Bool
  }
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)

data DerivationEventReset = DerivationEventReset
  { time :: UTCTime
  }
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)

data DerivationEventFailed = DerivationEventFailed
  { time :: UTCTime,
    technicalError :: Maybe Text
  }
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)

data DerivationEventSucceeded = DerivationEventSucceeded
  { time :: UTCTime
  }
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)

data DerivationEventCancelled = DerivationEventCancelled
  { time :: UTCTime
  }
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)

data DerivationEventForceCancelled = DerivationEventForceCancelled
  { time :: UTCTime,
    byUser :: Maybe SimpleAccount
  }
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)

data DerivationEventBuilt = DerivationEventBuilt
  { time :: UTCTime,
    outputs :: [BuiltOutput]
  }
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)

data DerivationEventHasCancelledForReset = DerivationEventHasCancelledForReset
  { time :: UTCTime
  }
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)

data DerivationEventHasCancelled = DerivationEventHasCancelled
  { time :: UTCTime
  }
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)
