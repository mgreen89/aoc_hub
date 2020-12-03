module Types exposing
    ( Model
    , Msg(..)
    )

import Dict exposing (Dict)
import EnTrance.Channel as Channel
import EnTrance.Types exposing (RpcData)
import UserDatabase exposing (GetAllUsersCmdResult, StoreNewUserCmdResult)
import UserType exposing (User)



-- MODEL


type alias Model =
    { participants : Dict String User
    , newName : String
    , newRepoUrl : String
    , newLanguages : String
    , storeResult : RpcData StoreNewUserCmdResult
    , getResult : RpcData GetAllUsersCmdResult
    , isUp : Bool
    , errors : List String
    , sendPort : Channel.SendPort Msg
    }



-- MESSAGES


type Msg
    = NameInput String
    | RunStoreCmd
    | RunGetCmd
    | RepoUrlInput String
    | LanguagesInput String
    | GotStoreResult (RpcData StoreNewUserCmdResult)
    | GotGetResult (RpcData GetAllUsersCmdResult)
    | ChannelIsUp Bool
    | Error String
