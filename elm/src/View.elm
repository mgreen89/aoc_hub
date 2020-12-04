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
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import RemoteData exposing (RemoteData(..))
import Types exposing (..)
import UserType exposing (User)


{-| Top-level view
-}
view : Model -> Html Msg
view model =
    Grid.container []
        [ Grid.row []
            [ Grid.col colSpec
                [ h4 [] [ text "Ensoft AoC 2020" ]
                , button [ onClick FetchGHData ] [ text "Fetch" ]
                , viewParticipants model.participants model.isUp
                , br [] []
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


formatUser : User -> Html msg
formatUser user =
    li [] [ a [ href user.repoUrl ] [ user.name ++ " " ++ user.repoUrl ++ " " ++ user.languages |> text ] ]


viewParticipants : Dict String User -> Bool -> Html Msg
viewParticipants participants isUp =
    div []
        [ ul [] (Dict.values participants |> List.map formatUser)
        ]


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
                    , placeholder "The languages you're using"
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
