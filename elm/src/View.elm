module View exposing (view)

{-| View
-}

import Bootstrap.Alert as Alert
import Bootstrap.Button as Button
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Progress as Progress
import Bootstrap.Table as Table
import DateTime
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Iso8601
import RemoteData exposing (RemoteData(..))
import Time
import Types exposing (..)
import UserType exposing (User)


{-| Top-level view
-}
view : Model -> Html Msg
view model =
    Grid.container [style "max-width" "1500px"]
        [ Grid.row []
            [ Grid.col colSpec
                [ h1 [ style "text-align" "center" ] [ a [ href "https://adventofcode.com/2020" ] [text "Ensoft AoC 2020" ]]
                , button [ onClick FetchGHData ] [ text "Fetch" ]
                , viewParticipants model.participants model.isUp
                , br [] []
                , h3 [ ] [ text "Add yourself!" ]
                , viewInput model
                ]
            ]
        ]


{-| Only display exit code if non-zero
-}
maybeCode : Int -> Html msg
maybeCode exitCode =
    if exitCode == 0 then
        text ""

    else
        div [ class "stderr" ] [ text ("Exit code " ++ String.fromInt exitCode) ]


formatUser : User -> Table.Row msg
formatUser user =
    let
        lastPushedString : String
        lastPushedString =
            case user.lastPushed of
                Just push ->
                    formatDate push.lastPushedTime

                Nothing ->
                    ""

        lastMessageString : String
        lastMessageString =
            case user.lastPushed of
                Just push ->
                    push.lastPushedMessage

                Nothing ->
                    ""
    in
    Table.tr []
        [ Table.td [] [ text user.name ]
        , Table.td [] [ a [ href user.repoUrl ] [ text user.repoUrl ] ]
        , Table.td [] [ text user.languages ]
        , Table.td [] [ text lastPushedString ]
        , Table.td [] [ text lastMessageString ]
        ]


formatDate : String -> String
formatDate iso_time =
    case Iso8601.toTime iso_time of
        Ok t ->
            let
                whole_date =
                    DateTime.fromPosix t

                date =
                    DateTime.getDay whole_date |> String.fromInt

                month =
                    DateTime.getMonth whole_date |> toEnglishMonth

                time =
                    DateTime.getTime whole_date

                hours =
                    DateTime.getHours whole_date |> String.fromInt |> String.padLeft 2 '0'

                minutes =
                    DateTime.getMinutes whole_date |> String.fromInt |> String.padLeft 2 '0'
            in
            date ++ " " ++ month ++ "     " ++ hours ++ ":" ++ minutes

        Err _ ->
            ""


toEnglishMonth : Time.Month -> String
toEnglishMonth month =
    case month of
        Time.Jan ->
            "Jan"

        Time.Feb ->
            "Feb"

        Time.Mar ->
            "Mar"

        Time.Apr ->
            "Apr"

        Time.May ->
            "May"

        Time.Jun ->
            "Jun"

        Time.Jul ->
            "Jul"

        Time.Aug ->
            "Aug"

        Time.Sep ->
            "Sep"

        Time.Oct ->
            "Oct"

        Time.Nov ->
            "Nov"

        Time.Dec ->
            "Dec"


viewParticipants : Dict String User -> Bool -> Html Msg
viewParticipants participants isUp =
    Table.simpleTable
        ( Table.simpleThead
            [ Table.th [] [ text "Name" ]
            , Table.th [] [ text "Repository URL" ]
            , Table.th [] [ text "Languages" ]
            , Table.th [] [ text "Last push (GitHub only for now)" ]
            , Table.th [] [ text "Last commit msg (GitHub only for now)" ]
            ]
        , Table.tbody []
            (Dict.values participants |> List.map formatUser)
        )


{-| View the input area
-}
viewInput : Model -> Html Msg
viewInput model =
    div []
        [ InputGroup.config
            (InputGroup.text
                [ Input.attrs
                    [ value model.newName
                    , autofocus True
                    , onInput NameInput
                    , placeholder "Your name"
                    ]
                ]
            )
            |> InputGroup.view
        , InputGroup.config
            (InputGroup.text
                [ Input.attrs
                    [ value model.newRepoUrl
                    , autofocus True
                    , onInput RepoUrlInput
                    , placeholder "Your repository URL"
                    ]
                ]
            )
            |> InputGroup.view
        , InputGroup.config
            (InputGroup.text
                [ Input.attrs
                    [ value model.newLanguages
                    , autofocus True
                    , onInput LanguagesInput
                    , placeholder "The language(s) you're using"
                    ]
                ]
            )
            |> InputGroup.successors
                [ InputGroup.button
                    [ Button.outlineInfo
                    , Button.attrs [ onClick RunStoreCmd ]
                    , Button.disabled (not model.isUp)
                    ]
                    [ text "Go!" ]
                ]
            |> InputGroup.view
        ]


{-| How the size should respond to the window size, expressed as units of a
grid 12 units across:

  - medium or bigger: 10 units wide (starting 1 from the left):
  - anything smaller: full width

You can see the effect by making your web browser window narrower and wider. A
more interesting example is in the `3_browser` view function, where there is
less need to support full-width content.

-}
colSpec : List (Col.Option msg)
colSpec =
    [ Col.md10
    , Col.offsetMd1
    ]
