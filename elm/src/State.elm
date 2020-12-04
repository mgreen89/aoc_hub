port module State exposing (initialModel, subscriptions, update)

import Dict exposing (Dict)
import EnTrance.Channel as Channel
import EnTrance.Request exposing (new)
import Http
import Json.Decode as Decode exposing (Decoder)
import RemoteData exposing (RemoteData(..))
import Response exposing (pure)
import Types exposing (..)
import UserDatabase
import UserType exposing (User)


{-| PORTS

  - `appSend` - send message to the server
  - `appRecv` - receive a notification from the server
  - `appIsUp` - get notifications of up/down status
  - `errorRecv` - get any global errors

-}
port appSend : Channel.SendPort msg


port appRecv : Channel.RecvPort msg


port appIsUp : Channel.IsUpPort msg


port errorRecv : Channel.ErrorRecvPort msg



-- INITIAL STATE


initialModel : Model
initialModel =
    { participants = Dict.fromList [ ( "Jackson", User "Jackson" "https://github.com/jacksonriley/aoc2020" "Rust" Nothing ) ]
    , newName = ""
    , newRepoUrl = ""
    , newLanguages = ""
    , storeResult = NotAsked
    , getResult = NotAsked
    , isUp = False
    , errors = []
    , sendPort = appSend
    , fetchResponse = FetchRepoDetails "" ""
    }


subscriptions : Sub Msg
subscriptions =
    Sub.batch
        [ errorRecv Error
        , appIsUp ChannelIsUp
        , Channel.sub appRecv Error notifications
        ]


notifications : List (Decoder Msg)
notifications =
    [ UserDatabase.decodeStoreNewUserCmd GotStoreResult
    , UserDatabase.decodeGetAllUsersCmd GotGetResult
    ]



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NameInput newName ->
            pure { model | newName = newName }

        RepoUrlInput newRepoUrl ->
            pure { model | newRepoUrl = newRepoUrl }

        LanguagesInput newLanguages ->
            pure { model | newLanguages = newLanguages }

        RunStoreCmd ->
            UserDatabase.storeNewUserCmd model.newName model.newRepoUrl model.newLanguages
                |> Channel.sendRpc
                    { model
                        | participants =
                            Dict.insert model.newName
                                (User model.newName
                                    model.newRepoUrl
                                    model.newLanguages
                                    Nothing
                                )
                                model.participants
                        , newName = ""
                        , newRepoUrl = ""
                        , newLanguages = ""
                        , storeResult = Loading
                    }

        -- TODO?
        RunGetCmd ->
            pure model

        GotStoreResult result ->
            pure { model | storeResult = result }

        GotGetResult result ->
            case result of
                Success data ->
                    pure
                        { model
                            | getResult = result
                            , participants = data
                        }

                _ ->
                    pure { model | getResult = result }

        ChannelIsUp isUp ->
            case isUp of
                True ->
                    UserDatabase.getAllUsersCmd
                        |> Channel.sendRpc
                            { model
                                | getResult = Loading
                                , isUp = isUp
                            }

                False ->
                    pure { model | isUp = isUp }

        Error error ->
            pure { model | errors = error :: model.errors }

        FetchGHData ->
            ( model, Dict.values model.participants |> List.filterMap getGHDetails |> List.map fetchCmd |> Cmd.batch )

        FetchGHResponse resp ->
            case resp of
                -- TODO - add into the User Dict
                Success info ->
                    case getParticipantByUrl info.html_url model of
                        Just u -> pure { model | fetchResponse = info
                                        ,participants=
                                            Dict.insert u.name
                                                (User u.name
                                                    u.repoUrl
                                                    u.languages
                                                    (Just info.pushed_at)
                                                )
                                            model.participants
                                        }
                            --     ,participants =
                        Nothing -> pure model

                _ ->
                    pure model

getParticipantByUrl:  String -> Model -> Maybe User
getParticipantByUrl url model =
    case Dict.values model.participants |> List.filter (\u -> u.repoUrl == url) of
        u::xs -> Just u
        [] -> Nothing

isUsingGitHub : User -> Bool
isUsingGitHub user =
    String.contains "github.com" user.repoUrl


getGHDetails : User -> Maybe GHDetails
getGHDetails user =
    if isUsingGitHub user then
    -- repoUrl e.g. https://github.com/jacksonriley/aoc2020
    case String.split "/" user.repoUrl |> List.reverse of
        repo::name::xs -> Just (GHDetails name repo)
        _ -> Nothing
    else Nothing


fetchCmd : GHDetails -> Cmd Msg
fetchCmd details =
    Http.get
        { url = "https://api.github.com/repos/" ++ details.username ++ "/" ++ details.reponame
        , expect =
            Http.expectJson (RemoteData.fromResult >> FetchGHResponse)
                fetchDecoder
        }


fetchDecoder : Decoder FetchRepoDetails
fetchDecoder =
    Decode.map2 FetchRepoDetails
        (Decode.field "html_url" Decode.string)
        (Decode.field "pushed_at" Decode.string)
