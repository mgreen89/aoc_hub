module Types exposing
    ( FetchRepoDetails
    , GHDetails
    , Model
    , Msg(..)
    )

import Bootstrap.Tab as Tab
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
    , tabState : Tab.State
    }



-- MESSAGES


type Msg
    = NameInput String
    | RunStoreCmd String
    | RunGetCmd
    | RepoUrlInput String
    | LanguagesInput String
    | GotStoreResult (RpcData StoreNewUserCmdResult)
    | GotGetResult (RpcData GetAllUsersCmdResult)
    | ChannelIsUp Bool
    | Error String
    | FetchGHData
    | FetchGHResponse (WebData (List FetchRepoDetails))
    | TabMsg Tab.State


type alias GHDetails =
    { username : String
    , reponame : String
    }


type alias FetchRepoDetails =
    { html_url : String
    , pushed_at : String
    , message : String
    }
