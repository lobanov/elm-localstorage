module LocalStorage exposing 
  ( Key
  , localGet, localPut, localRemove, localListKeys, localClear
  , sessionGet, sessionPut, sessionRemove, sessionListKeys, sessionClear
  )

{-| Exposes browser's `window.localStorage` and `window.sessionStorage` API as Elm Tasks.
Thanks to the latter, interactions with the local and session storage could be chained
or mixed with other Task-based APIs, such as [elm/http](https://package.elm-lang.org/packages/elm/http/latest/).

For example, consider an application that retrieves it's configuration from
the backend, but subsequently caches it in the window session, so it could
survive window refreshes even if there is no internet connectivity. Tasks allow
such logic to be expressed explicitly in Elm like the following.

    LocalStorage.sessionGet "config"
        |> Task.andThen Maybe.withDefault
            ( Http.task { method = "GET", {- ... fetch config from the backend -} }
                |> Task.andThen LocalStorage.sessionPut "config"
            )
        |> Task.attempt GotConfig
-}

import Json.Encode as JE
import Json.Decode as JD
import TaskPort exposing (Task, inNamespace, QualifiedName)

type alias Key = String

inNS : String -> QualifiedName
inNS = inNamespace "lobanov/elm-localstorage" "1.0.0"

{- Function names registered by JavaScript companion -}
localStorage = 
  { getItem = inNS "localGet"
  , putItem = inNS "localPut"
  , removeItem = inNS "localRemove"
  , listKeys = inNS "localList"
  , clear = inNS "localClear"
  }

sessionStorage =
  { getItem = inNS "sessionGet"
  , putItem = inNS "sessionPut"
  , removeItem = inNS "localRemove"
  , listKeys = inNS "sessionList"
  , clear = inNS "sessionClear"
  }

{-| Returns a Task retrieving a value from the browser's `window.localStorage` object.
The result will have `Nothing` if there is no value associated with a given key
in the local storage.

    type Msg = GotValue (TaskPort.Result (Maybe String))
    LocalStorage.localGet "key" |> Task.attempt GotValue
-}
localGet : Key -> Task (Maybe String)
localGet = get localStorage

{-| Returns a Task storing a value with a given key in the browser's `window.localStorage` object.
Most likely this is going to be used to synchronise browser's local storage with the application
model after it changes.

    type Msg = Saved (TaskPort.Result ())
    LocalStorage.localPut "key" "value" |> Task.attempt Saved
-}
localPut : Key -> String -> Task ()
localPut = put localStorage

{-| Returns a Task removing a value stored in the browser's `window.localStorage` object under a given key.

    type Msg = Saved (TaskPort.Result ())
    LocalStorage.localRemove "key" |> Task.attempt Removed
-}
localRemove : Key -> Task ()
localRemove = remove localStorage

{-| Returns a Task enumerating all keys in the browser's `window.localStorage` object.

    type Msg = GotKeys (TaskPort.Result (List String))
    LocalStorage.localListKeys "key" |> Task.attempt GotKeys
-}
localListKeys : Task (List Key)
localListKeys = listKeys localStorage

{-| Returns a Task deleting all items from the browser's `window.localStorage` object.
A good place to do this is when user clicks 'log off' button.

    type Msg = Cleared (TaskPort.Result ())
    LocalStorage.localClear |> Task.attempt Cleared
-}
localClear : Task ()
localClear = clear localStorage

{-| Returns a Task retrieving a value from the browser's `window.sessionStorage` object.
The result will have `Nothing` if there is no value associated with a given key
in the local storage.

    type Msg = GotValue (TaskPort.Result (Maybe String))
    LocalStorage.sessionGet "key" |> Task.attempt GotValue
-}
sessionGet : Key -> Task (Maybe String)
sessionGet = get sessionStorage

{-| Returns a Task storing a value with a given key in the browser's `window.sessionStorage` object.
Most likely this is going to be used to synchronise browser's window session state with the application
model after it changes.

    type Msg = Saved (TaskPort.Result ())
    LocalStorage.sessionPut "key" "value" |> Task.attempt Saved
-}
sessionPut : Key -> String -> Task ()
sessionPut = put sessionStorage

{-| Returns a Task removing a value stored in the browser's `window.localStorage` object under a given key.

    type Msg = Saved (TaskPort.Result ())
    LocalStorage.sessionRemove "key" |> Task.attempt Removed
-}
sessionRemove : Key -> Task()
sessionRemove = remove sessionStorage

{-| Returns a Task enumerating all keys in the browser's `window.sessionStorage` object.

    type Msg = GotKeys (TaskPort.Result (List Key))
    LocalStorage.sessionListKeys "key" |> Task.attempt GotKeys
-}
sessionListKeys : Task (List Key)
sessionListKeys = listKeys sessionStorage

{-| Returns a Task deleting all items from the browser's `window.sessionStorage` object.
A good place to do this is when user clicks 'log off' button.

    type Msg = Cleared (TaskPort.Result ())
    LocalStorage.sessionClear |> Task.attempt Cleared
-}
sessionClear : Task ()
sessionClear = clear sessionStorage

get : { names | getItem : QualifiedName } -> Key -> Task (Maybe String)
get names = TaskPort.callNS
  { function = names.getItem
  , valueDecoder = (JD.nullable JD.string)
  , argsEncoder = JE.string
  }

put : { names | putItem : QualifiedName } -> Key -> String -> Task ()
put names key value = 
  let
    encoder : ( String, String ) -> JE.Value
    encoder = \( k, v ) -> JE.object
      [ ( "key", JE.string k )
      , ( "value", JE.string v )
      ]
  in TaskPort.callNS 
    { function = names.putItem
    , valueDecoder = TaskPort.ignoreValue
    , argsEncoder = encoder
    }
    ( key, value )

remove : { names | removeItem : QualifiedName } -> Key -> Task ()
remove names = TaskPort.callNS
  { function = names.removeItem
  , valueDecoder = TaskPort.ignoreValue
  , argsEncoder = JE.string
  }

listKeys : { names | listKeys : QualifiedName } -> Task (List Key)
listKeys names = TaskPort.callNoArgsNS
  { function = names.listKeys
  , valueDecoder = (JD.list JD.string)
  }

clear : { names | clear : QualifiedName } -> Task ()
clear names = TaskPort.callNoArgsNS
  { function = names.clear
  , valueDecoder = TaskPort.ignoreValue
  }
