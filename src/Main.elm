module Main exposing (..)

import Browser
import Canvas exposing (..)
import Canvas.Settings exposing (..)
import Canvas.Settings.Line exposing (LineCap(..), lineCap)
import Color
import Html exposing (Html, div, h1, img, text)
import Html.Attributes exposing (src, style)


width : number
width =
    500


height : number
height =
    300



---- MODEL ----


type alias Model =
    {}


init : ( Model, Cmd Msg )
init =
    ( {}, Cmd.none )



---- UPDATE ----


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ Canvas.toHtml ( width, height )
            []
            [ shapes [ fill Color.white ] [ rect ( 0, 0 ) width height ]
            , shapes [ stroke Color.black ] [ path ( 100, 100 ) [ lineTo ( 200, 100 ) ] ]
            ]
        ]



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }
