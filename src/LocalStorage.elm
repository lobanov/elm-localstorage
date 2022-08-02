module LocalStorage exposing 
  ( Key
  , localGet, localPut, localRemove, localListKeys, localClear
  , sessionGet, sessionPut, sessionRemove, sessionListKeys, sessionClear
  )

{-| Exposes browser's `window.localStorage` and `window.sessionStorage` API as Elm Tasks.
Thanks to the latter, interactions with the local and session storage could be chained
or mixed with other Task-based APIs, such as [elm/http](https://package.elm-lang.org/packages/elm/http/latest/).

See package documentation for examples of using the module.

# General
@docs Key

# Local storage
@docs localGet, localPut, localRemove, localListKeys, localClear

# Session storage
@docs sessionGet, sessionPut, sessionRemove, sessionListKeys, sessionClear

-}

import Json.Encode as JE
import Json.Decode as JD
import TaskPort exposing (Task, inNamespace, QualifiedName)

{-| Convenience alias for string keys used to store and retrive values
in `window.localStorage` and `window.sessionStorage` objects.
-}
type alias Key = String

moduleVersion : String
moduleVersion = "1.0.1"

inNS : String -> QualifiedName
inNS = inNamespace "lobanov/elm-localstorage" moduleVersion

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
  , removeItem = inNS "sessionRemove"
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

It is likely you will need to store objects which are more complex than strings.
It is easy to chain the use of `Json.Encode.encode` as follow.

    Json.Encode.list Json.Encode.string [ 'v1', 'v2' ]
        |> Json.Encode.encode 0
        |> LocalStorage.localPut "key"
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

It is likely you will need to store objects which are more complex than strings.
It is easy to chain the use of `Json.Encode.encode` as follow.

    Json.Encode.list Json.Encode.string [ 'v1', 'v2' ]
        |> Json.Encode.encode 0
        |> LocalStorage.sessionPut "key"
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
