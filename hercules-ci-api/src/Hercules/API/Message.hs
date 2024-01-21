{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DerivingStrategies #-}

module Hercules.API.Message where

import Data.OpenApi qualified as O3
import Hercules.API.Prelude

data Message = Message
  { index :: Int,
    typ :: Type,
    message :: Text
  }
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)

data Type
  = -- | Something went wrong, inform user about possible
    -- cause. Examples: source could not be fetched, could not
    -- find a nix expression file to call.
    Error
  | -- | The nix expression contained a @builtins.trace@
    -- call. Ideally we should keep track of during which
    -- attribute it was encountered. It is not an attribute
    -- property because we can not reasonably know which
    -- attributes (plural) trigger the evaluation of
    -- @trace@. Indeed side effecting evaluation breaks the
    -- abstraction.
    Trace
  deriving (Generic, Show, Eq)
  deriving anyclass (NFData, ToJSON, FromJSON, ToSchema, O3.ToSchema)
