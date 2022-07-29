port module TestMain exposing (..)

import Task exposing (Task)
import TaskPort
import LocalStorage
import Json.Encode as JE
import Json.Decode as JD

port reportTestResult : ( String, Bool, String ) -> Cmd msg
port runTest : (Int -> msg) -> Sub msg

main : Program () Model Msg
main = Platform.worker
  { init = init
  , update = update
  , subscriptions = subscriptions
  }

type Model = Idle

type Msg = StartTest Int | TestCompleted Int (Result TestError ())

type TestError = OperationError String TaskPort.Error | ExpectationFailure String

init : () -> ( Model, Cmd Msg )
init _ = ( Idle, Cmd.none )

testErrorToString : TestError -> String
testErrorToString error =
  case error of
    OperationError name e -> name ++ " failed: " ++ (TaskPort.errorToString e)
    ExpectationFailure f -> f

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  ( Idle,
    case msg of
      StartTest i ->
        if i == 0 then Task.attempt (TestCompleted 0) test1
        else Cmd.none

      TestCompleted index (Result.Ok ()) -> reportTestResult ( "test" ++ (String.fromInt index), True, "" )
      TestCompleted index (Result.Err err) -> reportTestResult ( "test" ++ (String.fromInt index), False, testErrorToString err )
  )

debugLogMap : String -> (a -> b) -> a -> a
debugLogMap msg mapFn v = ( v, mapFn v ) |> Tuple.mapSecond (Debug.log msg) |> Tuple.first

test1 : Task TestError ()
test1 =
  let
    clear : Task TestError ()
    clear = LocalStorage.localClear |> Task.mapError (OperationError "clear")

    put : Task TestError ()
    put = LocalStorage.localPut "testKey" (JE.string "testValue") |> Task.mapError (OperationError "put")

    list : Task TestError (List String)
    list = LocalStorage.localListKeys |> Task.mapError (OperationError "list")

    getAndDecode : Task TestError String
    getAndDecode = LocalStorage.localGet "testKey" |> Task.mapError (OperationError "get")
      |> Task.andThen
        (\maybeValue -> 
          case maybeValue of
            Nothing -> Task.fail (ExpectationFailure "no value returned")
            Just v -> 
              let res = JD.decodeValue JD.string (debugLogMap "got" (JE.encode 0) v)
              in case result of
                Result.Ok string -> Task.succeed (Debug.log "decoded" string)
                Result.Err err -> Task.fail (ExpectationFailure ("invalid JSON value returned: " ++ JD.errorToString err))
        )

  in clear -- remove everything before testing
      |> Task.andThen (\_ -> put)
      |> Task.andThen (\_ -> list)
      |> Task.andThen
        (\keys ->
          if (List.length keys == 1 && List.member "testKey" keys) then
            Task.succeed ()
          else
            Task.fail (ExpectationFailure (String.join "," keys))
        )
      |> Task.andThen (\_ -> getAndDecode)
      |> Task.andThen
        (\value ->
          if (value == "testValue") then
            Task.succeed ()
          else
            Task.fail (ExpectationFailure value)
        )
      |> Task.andThen (\_ -> clear) -- clear everything after testing

subscriptions : Model -> Sub Msg
subscriptions _ = runTest StartTest
