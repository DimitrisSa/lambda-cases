{-# language LambdaCase #-}

module HaskellTypes.Generation where

import Control.Monad.State
  ( State, get, modify )
import qualified Data.Map as M
  ( Map, lookup, insert, empty, fromList )
--import Control.Monad.Trans.Except ( ExceptT )

import Helpers
  ( (.>), (==>) )

import HaskellTypes.LowLevel
  ( ValueName(..) )
import HaskellTypes.Types
  ( TypeName(..), BaseType(..), ValueType(..), FieldAndType, CaseAndType
  , FieldsOrCases )

{- 
  All:
  Types, get fields, update fields,
  value_map operations, type_map operations,
  initial state
-}

-- Types
type ValueMap =
  M.Map ValueName ValueType

type TypeMap =
  M.Map TypeName FieldsOrCases

data GenState =
  GS { indent_level :: Int, value_map :: ValueMap, type_map :: TypeMap }

-- type Stateful = ExceptT String (State GenState)
type Stateful = State GenState

-- get fields
get_from_state = ( \f -> get >>= f .> return )
  :: (GenState -> a) -> Stateful a

( get_indent_level, get_value_map, get_type_map ) =
  ( indent_level, value_map, type_map )==> \( i, v, t ) ->
  ( get_from_state i, get_from_state v, get_from_state t )
  :: ( Stateful Int, Stateful ValueMap, Stateful TypeMap )

-- update fields
( update_indent_level, update_value_map, update_type_map ) =
  ( \il -> modify ( \s -> s { indent_level = il } )
  , \vm -> modify ( \s -> s { value_map = vm } ) 
  , \tm -> modify ( \s -> s { type_map = tm } )
  ) :: ( Int -> Stateful (), ValueMap -> Stateful (), TypeMap -> Stateful () )

-- value_map operations
value_map_lookup = ( \vn@(VN s) -> get_value_map >>= M.lookup vn .> \case
  Nothing -> error $ "No definition for value: " ++ s
  Just vt -> return vt
  ) :: ValueName -> Stateful ValueType

value_map_insert = ( \vn vt -> get_value_map >>= M.insert vn vt .> update_value_map
  ) :: ValueName -> ValueType -> Stateful ()

-- type_map operations
type_map_lookup = ( \tn -> get_type_map >>= M.lookup tn .> return)
  :: TypeName -> Stateful (Maybe FieldsOrCases)

type_map_insert = ( \tn foc-> get_type_map >>= M.insert tn foc .> update_type_map) 
  :: TypeName -> FieldsOrCases -> Stateful ()

-- initial state
int_bt = TypeName $ TN "Int"
  :: BaseType

int_int_tuple_bt = TupleType $ replicate 2 (AbsTypesAndResType [] int_bt)
  :: BaseType

init_value_map = 
  M.fromList
    [ ( VN "div" , AbsTypesAndResType [ int_bt, int_bt ] int_bt)
    , ( VN "mod" , AbsTypesAndResType [ int_bt, int_bt ] int_bt)
    , ( VN "get_first" , AbsTypesAndResType [ int_int_tuple_bt ] int_bt)
    , ( VN "abs" , AbsTypesAndResType [ int_bt ] int_bt)
    , ( VN "max" , AbsTypesAndResType [ int_bt, int_bt ] int_bt)
    , ( VN "min" , AbsTypesAndResType [ int_bt, int_bt ] int_bt)
    ]
  :: ValueMap

init_state = GS 0 init_value_map M.empty
  :: GenState
