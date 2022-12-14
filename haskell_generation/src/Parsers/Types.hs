module Parsers.Types where

import Text.Parsec
  ( (<|>), many, char, lower, upper, string, sepBy, try, optionMaybe )
import Text.Parsec.String
  ( Parser )

import Helpers
  ( (==>), seperated2, eof_or_new_lines )

import HaskellTypes.Types
  ( TypeName(..), BaseType(..), ValueType(..), FieldAndType(..)
  , TupleType(..), CaseAndMaybeType(..), OrType(..), Type(..) )

import Parsers.LowLevel
  ( value_name_p )

-- All:
-- type_name_p, base_type_p, ValueType, field_and_type_p, tuple_type_p,
-- case_and_type_p, or_type_p, type_p

type_name_p =
  upper >>= \u -> many (lower <|> upper) >>= \lu -> return $ TN (u:lu)
  :: Parser TypeName

base_type_p =
  ParenTupleType <$>
     try (string "( " *> seperated2 ", " value_type_p <* string " )") <|>
  ParenthesisType <$> (char '(' *> value_type_p <* char ')') <|>
  TypeName <$> type_name_p 
  :: Parser BaseType

-- ValueType: value_type_p, one_ab_arrow_value_type_p, many_ab_arrows_value_type_p
value_type_p =
  try many_ab_arrows_value_type_p <|> one_ab_arrow_value_type_p
  :: Parser ValueType

one_ab_arrow_value_type_p =
  many (try $ base_type_p <* string " -> ") >>= \bts -> base_type_p >>= \bt ->
  return $ AbsTypesAndResType bts bt
  :: Parser ValueType

many_ab_arrows_value_type_p =
  seperated2 ", " one_ab_arrow_value_type_p >>= \vt1s ->
  string " *-> " >> one_ab_arrow_value_type_p >>= \(AbsTypesAndResType bts bt) ->
  return $ AbsTypesAndResType (map ParenthesisType vt1s ++ bts) bt
  :: Parser ValueType

field_and_type_p = 
  value_name_p >>= \vn -> string ": " >> value_type_p >>= \vt -> return $ FT vn vt
  :: Parser FieldAndType

tuple_type_p =
  string "tuple_type " >> type_name_p >>= \tn ->
  string "\nvalue ( " >> (field_and_type_p==>sepBy $ string ", ") <* string " )"
    >>= \ttv -> eof_or_new_lines >> NameAndValue tn ttv==>return
  :: Parser TupleType

case_and_type_p = 
  value_name_p >>= \vn -> optionMaybe (char '.' *> value_type_p) >>= \mvt ->
  return $ CT vn mvt
  :: Parser CaseAndMaybeType

or_type_p =
  string "or_type " >> type_name_p >>= \tn ->
  string "\nvalues " >> (case_and_type_p==>sepBy $ string " | ") >>= \otvs ->
  eof_or_new_lines >> NameAndValues tn otvs==>return
  :: Parser OrType

type_p = 
  TupleType <$> tuple_type_p <|> OrType <$> or_type_p
  :: Parser Type
