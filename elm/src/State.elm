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
import UserType exposing (..)


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
    { participants = Dict.fromList [ ( "https://github.com/jacksonriley/aoc2020", User "Jackson" "https://github.com/jacksonriley/aoc2020" "Rust" Nothing ) ]
    , newName = ""
    , newRepoUrl = ""
    , newLanguages = ""
    , storeResult = NotAsked
    , getResult = NotAsked
    , isUp = False
    , errors = []
    , sendPort = appSend
    , fetchResponse = FetchRepoDetails "" "" ""
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
                            Dict.insert model.newRepoUrl
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
                Success info_list ->
                    case info_list of
                        info :: xs ->
                            case getParticipantByUrl info.html_url model of
                                Just u ->
                                    pure
                                        { model
                                            | fetchResponse = info
                                            , participants =
                                                Dict.insert u.repoUrl
                                                    (User u.name
                                                        u.repoUrl
                                                        u.languages
                                                        (Just (PushInfo info.pushed_at info.message))
                                                    )
                                                    model.participants
                                        }

                                Nothing ->
                                    pure model

                        _ ->
                            pure model

                _ ->
                    pure model


getParticipantByUrl : String -> Model -> Maybe User
getParticipantByUrl url model =
    case Dict.values model.participants |> List.filter (\u -> String.contains u.repoUrl url) of
        u :: xs ->
            Just u

        [] ->
            Nothing


isUsingGitHub : User -> Bool
isUsingGitHub user =
    String.contains "github.com" user.repoUrl


getGHDetails : User -> Maybe GHDetails
getGHDetails user =
    if isUsingGitHub user then
        -- repoUrl e.g. https://github.com/jacksonriley/aoc2020
        case String.split "/" user.repoUrl |> List.reverse of
            repo :: name :: xs ->
                Just (GHDetails name repo)

            _ ->
                Nothing

    else
        Nothing


fetchCmd : GHDetails -> Cmd Msg
fetchCmd details =
    Http.get
        { url = "https://api.github.com/repos/" ++ details.username ++ "/" ++ details.reponame ++ "/commits"
        , expect =
            Http.expectJson (RemoteData.fromResult >> FetchGHResponse)
                fetchDecoder
        }


fetchDecoder : Decoder (List FetchRepoDetails)
fetchDecoder =
    Decode.list fetchDecoderItem


fetchDecoderItem : Decoder FetchRepoDetails
fetchDecoderItem =
    Decode.map3 FetchRepoDetails
        (Decode.field "html_url" Decode.string)
        (Decode.at [ "commit", "author", "date" ] Decode.string)
        (Decode.at [ "commit", "message" ] Decode.string)
