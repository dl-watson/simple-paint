module Main exposing (..)

import Browser
import Canvas exposing (..)
import Canvas.Settings exposing (..)
import Canvas.Settings.Line exposing (LineCap(..), lineCap)
import Color
import Html exposing (Html, div, h1, img, text)
import Html.Attributes exposing (src, style)
-- import Html.Events.Extra.Mouse as Mouse -- elm install mpizenberg/elm-point-events
-- import Html.Events.Extra.Touch as Touch -- when adding touch support

{- 
elm-canvas:
* path : Point -> List PathSegment -> Shape
    args: `path startingPoint segments`
    contains an implicit moveTo the starting point 
    in order to make a complex path, we need to put together a list of `PathSegment`s:
        * lineTo, bezierCurveTo, moveTo, etc

* point : (Float, Float)
    several of the `PathSegment` funcs take `Point`s as args

* shapes : List Setting -> List Shape -> Renderable

* clear : Point -> Float -> Float -> Renderable
    ex: `[ clear (0, 0) width height ]
    use `clear` to remove the contents of a rectangle in the screen and make them transparent

* Canvas.Settings.Line lineWidth : Float -> Setting
    specify the thickness of lines in space units

* Canvas.Settings.Line lineCap : LineCap -> Setting
    determines how the end points of every line are drawn
    see [lineCap](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineCap) for more usage details


elm-pointer-events:
* type alias Event =
    { ...
    , clientPos : ( Float, Float )
    , offsetPos : ( Float, Float )
    ...
    }
    mouseEvent.clientPos holds the ( clientX, clientY ) properties of the event
    when relative coordinates are needed, they are called offsetX/Y in a mouse event (available here with the attribute offsetPos)

* Mouse.onDown, .onMove, and .onUp (etc) are available with this package
-}

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
            , shapes [ stroke Color.black ] [ path ( 100, 100 ) [ lineTo ( 200, 150 ) ] ]
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
