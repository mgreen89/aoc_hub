module UserDatabase exposing
    ( StoreNewUserCmdResult
    , storeNewUserCmd
    , decodeStoreNewUserCmd
    , GetAllUsersCmdResult, decodeGetAllUsersCmd, getAllUsersCmd
    )

{-| This module provides a client-side typesafe interface to the
`insecure_shell` server-side feature, that runs an arbitrary shell command on
the server and sends back the result.

The feature is bespoke to this sample app (see `svr/run.py` for the other half)
but this is written as a standalone module that can be re-used as is.

@docs StoreNewUserCmdResult
@docs storeNewUserCmd
@docs decodeStoreNewUserCmd

-}

import Dict exposing (Dict)
import EnTrance.Feature.Gen as Gen
import EnTrance.Request as Request exposing (Request)
import EnTrance.Types exposing (RpcData)
import Json.Decode as Decode exposing (Decoder)
import UserType exposing (User)



-------------------------------------------------------------------------------
-- Store new user


type alias StoreNewUserCmdResult =
    { exitCode : Int }


{-| Request to do a command.
-}
storeNewUserCmd : String -> String -> String -> Request
storeNewUserCmd name url languages =
    Request.new "store_new_user"
        |> Request.addString "name" name
        |> Request.addString "url" url
        |> Request.addString "languages" languages


{-| Decode notifications from the server. Takes a message constructor.
-}
decodeStoreNewUserCmd : (RpcData StoreNewUserCmdResult -> msg) -> Decoder msg
decodeStoreNewUserCmd makeMsg =
    Gen.decodeRpc "store_new_user" decodeStoreNewUserCmdResult
        |> Decode.map makeMsg


decodeStoreNewUserCmdResult : Decoder StoreNewUserCmdResult
decodeStoreNewUserCmdResult =
    Decode.map StoreNewUserCmdResult
        (Decode.field "exit_code" Decode.int)



-------------------------------------------------------------------------------
-- Get all users


type alias GetAllUsersCmdResult =
    Dict String User



{-
   "[{"name": "Alice", "url": "some-url", "languages": "C, Python"},
     {"name": "Bob", "url": "some-other-url", "languages": "Rust"}]"
-}


getAllUsersCmd : Request
getAllUsersCmd =
    Request.new "get_all_users"


{-| Decode notifications from the server. Takes a message constructor.
-}
decodeGetAllUsersCmd : (RpcData GetAllUsersCmdResult -> msg) -> Decoder msg
decodeGetAllUsersCmd makeMsg =
    Gen.decodeRpc "get_all_users" decodeGetAllUsersCmdResult
        |> Decode.map makeMsg



decodeGetAllUsersCmdResult : Decoder GetAllUsersCmdResult
decodeGetAllUsersCmdResult =
    let
        userListToDict =
            List.foldl (\u d -> Dict.insert u.name u d) Dict.empty
    in
    Decode.list decodeUser
        |> Decode.map userListToDict


decodeUser : Decoder User
decodeUser =
    Decode.map3 User
        (Decode.field "name" Decode.string)
        (Decode.field "url" Decode.string)
        (Decode.field "languages" Decode.string)

