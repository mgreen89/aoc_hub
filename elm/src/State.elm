port module State exposing (initialModel, subscriptions, update)

import Dict exposing (Dict)
import EnTrance.Channel as Channel
import EnTrance.Request exposing (new)
import Json.Decode exposing (Decoder)
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
    { participants = Dict.fromList [ ( "Jackson", User "Jackson" "https://github.com/jacksonriley/aoc2020" "Rust" ) ]
    , newName = ""
    , newRepoUrl = ""
    , newLanguages = ""
    , storeResult = NotAsked
    , getResult = NotAsked
    , isUp = False
    , errors = []
    , sendPort = appSend
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
