{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE DuplicateRecordFields #-}

module Hercules.API.Effects.EffectEvent where

import Data.Aeson.Types (FromJSON (..), ToJSON (..), genericParseJSON, genericToEncoding, genericToJSON)
import Data.OpenApi qualified as O3
import Hercules.API.Prelude

data EffectEvent
  = Queued EffectEventQueued
  | DependencyFailed EffectEventDependencyFailed
  | Started EffectEventStarted
  | Failed EffectEventFailed
  | Succeeded EffectEventSucceeded
  | Cancelled EffectEventCancelled
  deriving (Generic, Show, Eq, NFData, ToSchema)

instance FromJSON EffectEvent where
  parseJSON = genericParseJSON schemaCompatibleOptions

instance ToJSON EffectEvent where
  toJSON = genericToJSON schemaCompatibleOptions

  toEncoding = genericToEncoding schemaCompatibleOptions

eventTime :: EffectEvent -> UTCTime
eventTime (Queued EffectEventQueued {time = t}) = t
eventTime (DependencyFailed EffectEventDependencyFailed {time = t}) = t
eventTime (Started EffectEventStarted {time = t}) = t
eventTime (Failed EffectEventFailed {time = t}) = t
eventTime (Succeeded EffectEventSucceeded {time = t}) = t
eventTime (Cancelled EffectEventCancelled {time = t}) = t

data EffectEventQueued = EffectEventQueued
  { time :: UTCTime
  }
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)

data EffectEventDependencyFailed = EffectEventDependencyFailed
  { time :: UTCTime
  }
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)

data EffectEventStarted = EffectEventStarted
  { time :: UTCTime,
    logId :: Id "log",
    agentHostname :: Text,
    agentVersion :: Text
  }
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)

data EffectEventReset = EffectEventReset
  { time :: UTCTime
  }
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)

data EffectEventFailed = EffectEventFailed
  { time :: UTCTime,
    technicalError :: Maybe Text
  }
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)

data EffectEventSucceeded = EffectEventSucceeded
  { time :: UTCTime
  }
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)

data EffectEventCancelled = EffectEventCancelled
  { time :: UTCTime
  }
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)
