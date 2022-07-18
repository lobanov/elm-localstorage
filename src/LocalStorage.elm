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

import Task exposing (Task)
import Json.Encode as JE
import Json.Decode as JD
import TaskPort

type alias Key = String
type alias Error = TaskPort.Error RuntimeError

{-| Type of errors generated by this module. As session and local storage APIs are not designed 
to throw errors, any failure would indicate something catastrophic in the browser environment,
and therefore wouldn't be recoverable.
-}
type alias RuntimeError = String

{- Function names registered by JavaScript companion -}
localStorage = 
  { getItem = "localStorageGetItem"
  , putItem = "localStoragePutItem"
  , listKeys = "localStorageListKeys"
  , clear = "localStorageClear"
  }

sessionStorage =
  { getItem = "sessionStorageGetItem"
  , putItem = "sessionStoragePutItem"
  , listKeys = "sessionStorageListKeys"
  , clear = "sessionStorageClear"
  }

{-| Creates a Task retrieving a value from the browser's `window.localStorage` object.

    LocalStorage.get "key" |> Task.attempt GotValue
-}
localGet : String -> Task Error (Maybe JE.Value)
localGet key = get localStorage key

{-| Creates a Task storing a value with a given key in the browser's `window.localStorage` object.
Most likely this is going to be used to synchronise browser's local storage with the application
model after it changes.

    Json.Encode.string "Hello, World!" |> LocalStorage.put "key" |> Task.attempt Saved
-}
localPut : String -> JE.Value -> Task Error ()
localPut key value = put localStorage key value

{-| Creates a Task enumerating all keys with a given prefix in the browser's `window.localStorage` object.
Most likely this is going to be using during the application initialization to syncrhonize
it's model with the browser local storage.

    LocalStorage.listKeys "app." |> Task.attempt Saved
-}
localListKeys : String -> Task Error (List String)
localListKeys prefix = listKeys localStorage prefix

{-| Creates a Task deleting all items with keys starting with a given string from the browser's `window.localStorage` object.
It can also be used to remove a single item using it's key. A good place to do this is when user clicks 'log off' button.

    LocalStorage.clear "app." |> Task.attempt Cleared
-}
localClear : String -> Task Error ()
localClear prefix = clear localStorage prefix


{-| Creates a Task retrieving a value from the browser's `window.sessionStorage` object.

    SessionStorage.get "key" |> Task.attempt GotValue
-}
sessionGet : String -> Task Error (Maybe JE.Value)
sessionGet key = get sessionStorage key

{-| Creates a Task storing a value with a given key in the browser's `window.sessionStorage` object.
Most likely this is going to be used to synchronise browser's window session state with the application
model after it changes.

    Json.Encode.string "Hello, World!" |> SessionStorage.put "key" |> Task.attempt Saved
-}
sessionPut : String -> JE.Value -> Task Error ()
sessionPut key value = put sessionStorage key value

{-| Creates a Task enumerating all keys with a given prefix in the browser's `window.sessionStorage` object.
Most likely this is going to be using during the application initialization to syncrhonize
it's model with the window session.

    SessionStorage.listKeys "app." |> Task.attempt Saved
-}
sessionListKeys : String -> Task Error (List String)
sessionListKeys prefix = listKeys sessionStorage prefix

{-| Creates a Task deleting all items with keys starting with a given string from the browser's `window.sessionStorage` object.
It can also be used to remove a single item using it's key. A good place to do this is when user clicks 'log off' button.

    SessionStorage.clear "app." |> Task.attempt Cleared
-}
sessionClear : String -> Task Error ()
sessionClear prefix = clear sessionStorage prefix


get : { names | getItem : String } -> String -> Task Error (Maybe JE.Value)
get names key = TaskPort.call names.getItem (JD.nullable JD.value) JD.string JE.string key

put : { names | putItem : String } -> String -> JE.Value -> Task Error ()
put names key value = 
  let
    argsEncoder : ( String, JE.Value ) -> JE.Value
    argsEncoder = \( k, v ) -> JE.object
      [ ( "key", JE.string k )
      , ( "value", v )
      ]
    in TaskPort.call names.putItem (JD.null ()) JD.string argsEncoder ( key, value )

listKeys : { names | listKeys : String } -> String -> Task Error (List String)
listKeys names prefix = TaskPort.call names.listKeys (JD.list JD.string) JD.string JE.string prefix

clear : { names | clear : String } -> String -> Task Error ()
clear names prefix = TaskPort.call names.clear (JD.null ()) JD.string JE.string prefix
