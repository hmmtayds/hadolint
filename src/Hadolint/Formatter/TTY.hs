{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}

module Hadolint.Formatter.TTY
  ( printResult,
    formatError,
    formatChecks,
  )
where

import Data.Semigroup ((<>))
import qualified Data.Text as Text
import Hadolint.Formatter.Format
import Hadolint.Rules
import Language.Docker.Syntax
import Text.Megaparsec (TraversableStream)
import Text.Megaparsec.Error
import Text.Megaparsec.Stream (VisualStream)

formatErrors :: (VisualStream s, TraversableStream s, ShowErrorComponent e, Functor f) => f (ParseErrorBundle s e) -> f String
formatErrors = fmap formatError

formatError :: (VisualStream s, TraversableStream s, ShowErrorComponent e) => ParseErrorBundle s e -> String
formatError err = stripNewlines (errorMessageLine err)

formatChecks :: Functor f => f RuleCheck -> f Text.Text
formatChecks = fmap formatCheck
  where
    formatCheck (RuleCheck meta source line _) =
      formatPos source line <> code meta <> " " <> message meta

formatPos :: Filename -> Linenumber -> Text.Text
formatPos source line = source <> ":" <> Text.pack (show line) <> " "

printResult :: (VisualStream s, TraversableStream s, ShowErrorComponent e) => Result s e -> IO ()
printResult Result {errors, checks} = printErrors >> printChecks
  where
    printErrors = mapM_ putStrLn (formatErrors errors)
    printChecks = mapM_ (putStrLn . Text.unpack) (formatChecks checks)
