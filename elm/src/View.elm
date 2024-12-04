module View exposing (view)

{-| View
-}

import Bootstrap.Button as Button
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Tab as Tab
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
    Tab.config TabMsg
        |> Tab.items
            [ Tab.item
                { id = "2020"
                , link = Tab.link [] [ text "2020" ]
                , pane = Tab.pane [] [ viewYear "2020" model ]
                }
            , Tab.item
                { id = "2021"
                , link = Tab.link [] [ text "2021" ]
                , pane = Tab.pane [] [ viewYear "2021" model ]
                }
            , Tab.item
                { id = "2022"
                , link = Tab.link [] [ text "2022" ]
                , pane = Tab.pane [] [ viewYear "2022" model ]
                }
            , Tab.item
                { id = "2023"
                , link = Tab.link [] [ text "2023" ]
                , pane = Tab.pane [] [ viewYear "2023" model ]
                }
            , Tab.item
                { id = "2024"
                , link = Tab.link [] [ text "2024" ]
                , pane = Tab.pane [] [ viewYear "2024" model ]
                }
            ]
        |> Tab.view model.tabState


viewYear : String -> Model -> Html Msg
viewYear year model =
    Grid.container [ style "max-width" "1500px" ]
        [ Grid.row []
            [ Grid.col colSpec
                [ h1 [ style "text-align" "center" ] [ a [ href ("https://adventofcode.com/" ++ year) ] [ text ("Ensoft AoC " ++ year) ] ]
                , h4 [ style "text-align" "center" ] (if year == "2023" || year == "2024" then [ text "Private Leaderboard Code: 861630-cfbd3281" ] else [])
                , viewParticipants year model.participants
                , br [] []
                , div [ style "text-align" "center" ] [ Button.button [ Button.outlinePrimary, Button.attrs [ onClick FetchGHData ] ] [ text "Update GitHub info" ] ]
                , h3 [] [ text "Add yourself!" ]
                , viewInput year model
                ]
            ]
        ]


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


viewParticipants : String -> Dict String User -> Html Msg
viewParticipants year participants =
    Table.simpleTable
        ( Table.simpleThead
            [ Table.th [] [ text "Name" ]
            , Table.th [] [ text "Repository URL" ]
            , Table.th [] [ text "Languages" ]
            , Table.th [] [ text "Last push (GitHub only for now)" ]
            , Table.th [] [ text "Last commit msg (GitHub only for now)" ]
            ]
        , Table.tbody []
            (Dict.values participants |> List.sortBy .name |> List.filter (\p -> p.year == year) |> List.map formatUser)
        )


{-| View the input area
-}
viewInput : String -> Model -> Html Msg
viewInput year model =
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
                    , Button.attrs [ onClick (RunStoreCmd year) ]
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
