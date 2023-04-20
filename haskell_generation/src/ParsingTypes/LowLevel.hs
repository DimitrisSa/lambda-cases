module ParsingTypes.LowLevel where

import Data.List (intercalate)
import Helpers ((==>), (.>))

-- All: Types, Show instances

-- Types: ValueName, Literal, Abstraction, ManyAbstractions, Input

newtype ValueName =
  VN String deriving (Eq, Ord)

data Literal =
  Integer Integer | Char Char | String String

data Abstraction =
  AbstractionName ValueName | UseFields

data ManyAbstractions =
  Abstractions Abstraction Abstraction [ Abstraction ]

data Input =
  OneAbstraction Abstraction | ManyAbstractions ManyAbstractions 

-- Show instances: ValueName, Literal, Abstraction, ManyAbstractions, Input

instance Show ValueName where
  show = \(VN n) -> n

instance Show Literal where
  show = \case
    Integer integer -> show integer
    Char char -> [ char ]
    String string -> string

instance Show Abstraction where
  show = \case
    AbstractionName value_name -> show value_name
    UseFields -> "use_fields"

instance Show ManyAbstractions where
  show = \(Abstractions abs1 abs2 rest_of_abs) ->
    "(" ++ map show (abs1 : abs2 : rest_of_abs)==>intercalate ", " ++ ")"

instance Show Input where
  show = show_input .> (++ " -> ") where
    show_input = \case
      OneAbstraction abstraction -> show abstraction
      ManyAbstractions abstractions -> show abstractions