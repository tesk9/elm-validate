module Validate (Validator, all, any, eager, ifBlank, ifNotInt, ifEmptyDict, ifEmptySet, ifInvalid) where
{-| Convenience functions for validating data.

# Validating a subject
@docs Validator, ifBlank, ifNotInt, ifEmptyDict, ifEmptySet, ifInvalid


# Combining validators
@docs all, any, eager
-}

import String
import Regex
import Dict exposing (Dict)
import Set exposing (Set)


{-| A `Validator` is a function which takes a subject and returns a list of errors
describing anything invalid about that subject.

An empty error list means the subject was valid.
-}
type alias Validator error subject =
    (subject -> List error)


{-| Run each of the given validators, in order, and return their concatenated
error lists.
-}
all : List (Validator error subject) -> Validator error subject
all validators =
    let
        validator subject =
            let
                accumulateErrors currentValidator totalErrors =
                    totalErrors ++ (currentValidator subject)
            in
                List.foldl accumulateErrors [] validators
    in
        validator


{-| Run each of the given validators, in order, stopping after the first error
and returning it. If no errors are encountered, return `Nothing`.
-}
eager : List (Validator error subject) -> subject -> Maybe error
eager validators subject =
    case validators of
        [] ->
            Nothing

        validator :: others ->
            case validator subject of
                [] ->
                    eager others subject

                error :: _ ->
                    Just error


{-| Return `True` if none of the given validators returns any errors for the given
subject, and `False` if any validator returns one or more errors.
-}
any : List (Validator error subject) -> subject -> Bool
any validators subject =
    case validators of
        [] ->
            True

        validator :: others ->
            case validator subject of
                [] ->
                    any others subject

                error :: _ ->
                    False


{-| Return an error if the given `String` is empty, or if it contains only
whitespace characters. -}
ifBlank : error -> Validator error String
ifBlank =
    ifInvalid (Regex.contains lacksNonWhitespaceChars)


lacksNonWhitespaceChars =
    Regex.regex "^\\s*$"


{-| Return an error if the given `String` cannot be parsed as an `Int`. -}
ifNotInt : error -> Validator error String
ifNotInt error subject =
    case String.toInt subject of
        Ok _ ->
            []

        Err _ ->
            [error]


{-| Return an error if the given `Dict` is empty. -}
ifEmptyDict : error -> Validator error (Dict comparable v)
ifEmptyDict =
    ifInvalid Dict.isEmpty


{-| Return an error if the given `Set` is empty. -}
ifEmptySet : error -> Validator error (Set comparable)
ifEmptySet =
    ifInvalid Set.isEmpty


{-| Return an error if the given predicate returns `True` for the given
subject. -}
ifInvalid : (subject -> Bool) -> error -> Validator error subject
ifInvalid test error =
    let
        validator subject =
            if test subject then
                [error]
            else
                []
    in
        validator
