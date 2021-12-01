port module State exposing (initialModel, subscriptions, update)

import Bootstrap.Tab as Tab
import Dict exposing (Dict)
import EnTrance.Channel as Channel
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
    { participants = Dict.empty
    , newName = ""
    , newRepoUrl = ""
    , newLanguages = ""
    , storeResult = NotAsked
    , getResult = NotAsked
    , isUp = False
    , errors = []
    , sendPort = appSend
    , fetchResponse = FetchRepoDetails "" "" ""
    , tabState = Tab.customInitialState "2021"
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

        RunStoreCmd year ->
            UserDatabase.storeNewUserCmd model.newName model.newRepoUrl model.newLanguages year
                |> Channel.sendRpc
                    { model
                        | participants =
                            Dict.insert model.newRepoUrl
                                (User model.newName
                                    model.newRepoUrl
                                    model.newLanguages
                                    year
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
            ( { model | storeResult = result }, createFetchGHCmd model.participants )

        GotGetResult result ->
            case result of
                Success data ->
                    --  Update the model, and fetch the GH data
                    ( { model
                        | getResult = result
                        , participants = data
                      }
                    , createFetchGHCmd data
                    )

                _ ->
                    pure { model | getResult = result }

        ChannelIsUp isUp ->
            if isUp then
                UserDatabase.getAllUsersCmd
                    |> Channel.sendRpc
                        { model
                            | getResult = Loading
                            , isUp = isUp
                        }

            else
                pure { model | isUp = isUp }

        Error error ->
            pure { model | errors = error :: model.errors }

        FetchGHData ->
            ( model, createFetchGHCmd model.participants )

        FetchGHResponse resp ->
            case resp of
                -- TODO - add into the User Dict
                Success info_list ->
                    case info_list of
                        info :: _ ->
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
                                                        u.year
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

        TabMsg state ->
            pure { model | tabState = state }


{-|

    Construct a batch of fetchCmd to retrieve GitHub info for all of the
    participants.

-}
createFetchGHCmd : Dict String User -> Cmd Msg
createFetchGHCmd participants =
    Dict.values participants |> List.filterMap getGHDetails |> List.map (fetchCmd "oJYQsqm301XNTFCXU40l871") |> Cmd.batch


getParticipantByUrl : String -> Model -> Maybe User
getParticipantByUrl url model =
    case Dict.values model.participants |> List.filter (\u -> String.contains u.repoUrl url) of
        u :: _ ->
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
            repo :: name :: _ ->
                Just (GHDetails name repo)

            _ ->
                Nothing

    else
        Nothing


fetchCmd : String -> GHDetails -> Cmd Msg
fetchCmd token_end details =
    Http.request
        { method = "GET"

        -- This token is a personal access token which can be generated from
        -- https://github.com/settings/tokens. It allows for a higher
        -- rate-limit for the GitHub API (currently 5000 requests per hour).
        -- The MEGA hacky splitting of the token is because GitHub
        -- automatically revokes any tokens that you push! Helpful in general
        -- but since this token doesn't give any permissions I'm not worried
        -- about it leaking.
        -- Constructing the token inline doesn't work because the Elm compiler
        -- is too smart and does this at compile time, leaving the full token
        -- in the generated Javascipt!
        , headers = [ Http.header "Authorization" ("token ghp_Hr5Q1rGfujU37" ++ token_end) ]
        , url = "https://api.github.com/repos/" ++ details.username ++ "/" ++ details.reponame ++ "/commits"
        , body = Http.emptyBody
        , expect =
            Http.expectJson (RemoteData.fromResult >> FetchGHResponse)
                fetchDecoder
        , timeout = Nothing
        , tracker = Nothing
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
