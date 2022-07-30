port module TestMain exposing (..)

import Task exposing (Task)
import TaskPort
import LocalStorage exposing (Key)
import Json.Encode as JE
import Json.Decode as JD

port reportTestResult : ( Int, Bool, String ) -> Cmd msg
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
      StartTest 0 -> Task.attempt (TestCompleted 0) (roundTripTest localStorageTasks)
      StartTest 1 -> Task.attempt (TestCompleted 1) (roundTripTest sessionStorageTasks)
      StartTest _ -> Cmd.none

      TestCompleted index (Result.Ok ()) -> reportTestResult ( index, True, "" )
      TestCompleted index (Result.Err err) -> reportTestResult ( index, False, testErrorToString err )
  )

localStorageTasks =
  { clear = LocalStorage.localClear |> Task.mapError (OperationError "clear")
  , put = \k v -> LocalStorage.localPut k v |> Task.mapError (OperationError "put")
  , list = LocalStorage.localListKeys |> Task.mapError (OperationError "list")
  , remove = \k -> LocalStorage.localRemove k |> Task.mapError (OperationError "remove")
  , getAndUnwrap = \k -> LocalStorage.localGet k |> Task.mapError (OperationError "get")
      |> Task.andThen
        (\maybeValue -> 
          case maybeValue of
            Nothing -> Task.fail (ExpectationFailure "no value returned")
            Just string -> Task.succeed string
        )
  }

sessionStorageTasks =
  { clear = LocalStorage.sessionClear |> Task.mapError (OperationError "clear")
  , put = \k v -> LocalStorage.sessionPut k v |> Task.mapError (OperationError "put")
  , list = LocalStorage.sessionListKeys |> Task.mapError (OperationError "list")
  , remove = \k -> LocalStorage.sessionRemove k |> Task.mapError (OperationError "remove")
  , getAndUnwrap = \k -> LocalStorage.sessionGet k |> Task.mapError (OperationError "get")
      |> Task.andThen
        (\maybeValue -> 
          case maybeValue of
            Nothing -> Task.fail (ExpectationFailure "no value returned")
            Just string -> Task.succeed string
        )
  }

roundTripTest tasks = tasks.clear -- remove everything before testing
  |> Task.andThen (\_ -> tasks.put "testKey" "testValue")
  |> Task.andThen (\_ -> tasks.list)
  |> Task.andThen
    (\keys ->
      if (List.length keys == 1 && List.member "testKey" keys) then
        Task.succeed ()
      else
        Task.fail (ExpectationFailure ("should have 'testKey' after successful put: " ++ String.join "," keys))
    )
  |> Task.andThen (\_ -> tasks.getAndUnwrap "testKey")
  |> Task.andThen
    (\value ->
      if (value == "testValue") then
        Task.succeed ()
      else
        Task.fail (ExpectationFailure ("should have got 'testValue' after successful get: " ++ value))
    )
  |> Task.andThen (\_ -> tasks.remove "testKey")
  |> Task.andThen (\_ -> tasks.list)
  |> Task.andThen
    (\keys ->
      if (List.isEmpty keys) then
        Task.succeed ()
      else
        Task.fail (ExpectationFailure ("should be empty after successful remove: " ++ String.join "," keys))
    )
  |> Task.andThen (\_ -> tasks.clear) -- clear everything after testing

subscriptions : Model -> Sub Msg
subscriptions _ = runTest StartTest
