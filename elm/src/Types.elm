module Types exposing
    ( Model
    , Msg(..)
    , GHDetails
    , FetchRepoDetails
    )

import Dict exposing (Dict)
import EnTrance.Channel as Channel
import EnTrance.Types exposing (RpcData)
import RemoteData exposing (RemoteData(..), WebData)
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
    , fetchResponse : FetchRepoDetails
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
    | FetchGHData
    | FetchGHResponse (WebData FetchRepoDetails)

type alias GHDetails =
    { username : String
    , reponame : String
    }

type alias FetchRepoDetails = {
    html_url : String
    , pushed_at : String
    }