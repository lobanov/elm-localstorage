module LocalStorage exposing 
  ( Key
  , localGet, localPut, localListKeys, localClear
  , sessionGet, sessionPut, sessionListKeys, sessionClear
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
import TaskPort exposing (Task, inNamespace, QualifiedName, ignoreValue)

type alias Key = String

inNS : String -> QualifiedName
inNS = inNamespace "lobanov/elm-localstorage" "1.0.0"

{- Function names registered by JavaScript companion -}
localStorage = 
  { getItem = inNS "localGet"
  , putItem = inNS "localPut"
  , listKeys = inNS "localList"
  , clear = inNS "localClear"
  }

sessionStorage =
  { getItem = inNS "sessionGet"
  , putItem = inNS "sessionPut"
  , listKeys = inNS "sessionList"
  , clear = inNS "sessionClear"
  }

{-| Creates a Task retrieving a value from the browser's `window.localStorage` object.

    LocalStorage.get "key" |> Task.attempt GotValue
-}
localGet : String -> Task (Maybe JE.Value)
localGet = get localStorage

{-| Creates a Task storing a value with a given key in the browser's `window.localStorage` object.
Most likely this is going to be used to synchronise browser's local storage with the application
model after it changes.

    Json.Encode.string "Hello, World!" |> LocalStorage.put "key" |> Task.attempt Saved
-}
localPut : String -> JE.Value -> Task ()
localPut = put localStorage

{-| Creates a Task enumerating all keys with a given prefix in the browser's `window.localStorage` object.
Most likely this is going to be using during the application initialization to syncrhonize
it's model with the browser local storage.

    LocalStorage.listKeys "app." |> Task.attempt Saved
-}
localListKeys : String -> Task (List String)
localListKeys = listKeys localStorage

{-| Creates a Task deleting all items with keys starting with a given string from the browser's `window.localStorage` object.
It can also be used to remove a single item using it's key. A good place to do this is when user clicks 'log off' button.

    LocalStorage.clear "app." |> Task.attempt Cleared
-}
localClear : String -> Task ()
localClear = clear localStorage


{-| Creates a Task retrieving a value from the browser's `window.sessionStorage` object.

    SessionStorage.get "key" |> Task.attempt GotValue
-}
sessionGet : String -> Task (Maybe JE.Value)
sessionGet = get sessionStorage

{-| Creates a Task storing a value with a given key in the browser's `window.sessionStorage` object.
Most likely this is going to be used to synchronise browser's window session state with the application
model after it changes.

    Json.Encode.string "Hello, World!" |> SessionStorage.put "key" |> Task.attempt Saved
-}
sessionPut : String -> JE.Value -> Task ()
sessionPut = put sessionStorage

{-| Creates a Task enumerating all keys with a given prefix in the browser's `window.sessionStorage` object.
Most likely this is going to be using during the application initialization to syncrhonize
it's model with the window session.

    SessionStorage.listKeys "app." |> Task.attempt Saved
-}
sessionListKeys : String -> Task (List String)
sessionListKeys = listKeys sessionStorage

{-| Creates a Task deleting all items with keys starting with a given string from the browser's `window.sessionStorage` object.
It can also be used to remove a single item using it's key. A good place to do this is when user clicks 'log off' button.

    SessionStorage.clear "app." |> Task.attempt Cleared
-}
sessionClear : String -> Task ()
sessionClear = clear sessionStorage

get : { names | getItem : QualifiedName } -> String -> Task (Maybe JE.Value)
get names = TaskPort.callNS
  { function = names.getItem
  , valueDecoder = (JD.nullable JD.value)
  , argsEncoder = JE.string
  }

put : { names | putItem : QualifiedName } -> String -> JE.Value -> Task ()
put names key value = 
  let
    encoder : ( String, JE.Value ) -> JE.Value
    encoder = \( k, v ) -> JE.object
      [ ( "key", JE.string k )
      , ( "value", v )
      ]
    in TaskPort.callNS 
      { function = names.putItem
      , valueDecoder = TaskPort.ignoreValue
      , argsEncoder = encoder
      }
      ( key, value )

listKeys : { names | listKeys : QualifiedName } -> String -> Task (List String)
listKeys names prefix = TaskPort.callNS
  { function = names.listKeys
  , valueDecoder = (JD.list JD.string)
  , argsEncoder = JE.string
  }
  prefix

clear : { names | clear : QualifiedName } -> String -> Task ()
clear names prefix = TaskPort.callNS
  { function = names.clear
  , valueDecoder = TaskPort.ignoreValue
  , argsEncoder = JE.string
  }
  prefix
