module TestMain exposing (..)

import Task
import TaskPort
import LocalStorage
import Json.Encode as JE
import Json.Decode as JD

main : Program () Model Msg
main = Platform.worker
  { init = init
  , update = update
  , subscriptions = subscriptions
  }

type alias Model = ()

type Msg = Started (TaskPort.Result ())

init : () -> ( Model, Cmd Msg )
init _ = 
  ( ()
  , LocalStorage.localPut "testKey" (JE.string "testValue") |> Task.attempt Started
  )

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model = ( model, Cmd.none )

subscriptions : Model -> Sub Msg
subscriptions _ = Sub.none
