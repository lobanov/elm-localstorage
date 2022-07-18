module LocalStorage exposing (get, put, listKeys, clear)

{-| Exposes browser's `window.localStorage` API as a collection of Elm Tasks.
Thanks to the latter, interactions with the session storage could be chained
or mixed with other Task-based APIs, such as Http.

You may also want to consider `SessionStorage` module for accessing `window.sessionStorage` API.

For example, consider an application that retrieves it's configuration from
the backend, but subsequently caches it in the local store, so it could
survive window refreshes even if there is no internet connectivity. Tasks allow
such logic to be expressed explicitly in Elm like the following.

    LocalStorage.get "config"
        |> Task.andThen Maybe.withDefault
            ( Http.task { method = "GET", {- ... fetch config from the backend -} }
                |> Task.andThen LocalStorage.put "config"
            )
        |> Task.attempt GotConfig
-}

import Task exposing (Task)
import Json.Encode as JE
import Json.Decode as JD
import TaskPort

type alias Error = TaskPort.Error String

{- Function names registered by JavaScript companion -}
names = 
  { getItem = "localStorageGetItem"
  , putItem = "localStoragePutItem"
  , removeItem = "localStorageRemoveItem"
  , listKeys = "localStorageListKeys"
  , clear = "localStorageClear"
  }

{-| Creates a Task retrieving a value from the browser's `window.localStorage` object.

    LocalStorage.get "key" |> Task.attempt GotValue
-}
get : String -> Task Error (Maybe JE.Value)
get key = TaskPort.call names.getItem (JD.nullable JD.value) JD.string JE.string key

{-| Creates a Task storing a value with a given key in the browser's `window.localStorage` object.
Most likely this is going to be used to synchronise browser's local storage with the application
model after it changes.

    Json.Encode.string "Hello, World!" |> LocalStorage.put "key" |> Task.attempt Saved
-}
put : String -> JE.Value -> Task Error ()
put key value = 
  let
    argsEncoder : ( String, JE.Value ) -> JE.Value
    argsEncoder = \( k, v ) -> JE.object
      [ ( "key", JE.string k )
      , ( "value", v )
      ]
    in TaskPort.call names.putItem (JD.null ()) JD.string argsEncoder ( key, value )

{-| Creates a Task enumerating all keys with a given prefix in the browser's `window.localStorage` object.
Most likely this is going to be using during the application initialization to syncrhonize
it's model with the browser local storage.

    LocalStorage.listKeys "app." |> Task.attempt Saved
-}
listKeys : String -> Task Error (List String)
listKeys prefix = TaskPort.call names.listKeys (JD.list JD.string) JD.string JE.string prefix

{-| Creates a Task deleting all items with keys starting with a given string from the browser's `window.localStorage` object.
It can also be used to remove a single item using it's key. A good place to do this is when user clicks 'log off' button.

    LocalStorage.clear "app." |> Task.attempt Cleared
-}
clear : String -> Task Error ()
clear prefix = TaskPort.call names.clear (JD.null ()) JD.string JE.string prefix
