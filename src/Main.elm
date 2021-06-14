module Main exposing (..)

-- elm install mpizenberg/elm-point-events
-- import Html.Events.Extra.Touch as Touch -- when adding touch support

import Browser
import Canvas exposing (..)
import Canvas.Settings exposing (..)
import Canvas.Settings.Line exposing (LineCap(..), lineCap)
import Color
import Debug exposing (log)
import Html exposing (Html, aside, div, h1, img, text)
import Html.Attributes exposing (src, style)
import Html.Events.Extra.Mouse as Mouse



-- [elm-canvas](https://package.elm-lang.org/packages/joakin/elm-canvas/4.3.0/)
-- [elm-pointer-events Extra.Mouse](https://package.elm-lang.org/packages/mpizenberg/elm-pointer-events/latest/Html-Events-Extra-Mouse)
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
-- (x, ) coordinatees


type alias Point =
    ( Float, Float )



-- A stroke is the mouse positions from the user's mousedown until their mouseup


type alias Stroke =
    List Point


type alias Model =
    { -- All of the strokes made in our app, form the drawing
      strokes : List Stroke

    -- Possible alternative design involves holding a buffer to the current stroke, and using "strokes" to hold all *previously* finished strokes
    -- , currentStroke : Stroke
    , isDrawing : Bool
    }


init : ( Model, Cmd Msg )
init =
    ( { strokes = []

      -- when Mouse.onDown -> isDrawing = True
      , isDrawing = False
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = NoOp
    | CanvasMouseDown Point
    | CanvasMouseMove Point
    | CanvasMouseUp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( case msg of
        NoOp ->
            model

        CanvasMouseDown point ->
            { model
                | isDrawing = True
                , strokes = [ point ] :: model.strokes
            }

        CanvasMouseMove point ->
            -- get the most recent stroke out of model.strokes, add this point to it, and update model.strokes to have this *new* list as its beginning
            let
                prevStroke =
                    List.head model.strokes |> Maybe.withDefault [ point ]

                currentStroke =
                    point :: prevStroke

                -- add the point the mouse is at to the most recent stroke
                listWithoutPrevStroke =
                    List.tail model.strokes |> Maybe.withDefault model.strokes

                -- remove the most recent stroke from the list so we can add back the updated version of it
            in
            if model.isDrawing then
                { model | strokes = currentStroke :: listWithoutPrevStroke }

            else
                model

        -- CanvasMouseMove will acculumate the points into a stroke
        CanvasMouseUp ->
            { model | isDrawing = False }
    , Cmd.none
    )



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ Canvas.toHtml ( width, height )
            [ Mouse.onDown (.offsetPos >> CanvasMouseDown)
            , Mouse.onMove (.offsetPos >> CanvasMouseMove)
            , Mouse.onUp (\_ -> CanvasMouseUp)
            ]
            -- ^^ Attributes
            [ shapes [ fill Color.white ] [ rect ( 0, 0 ) width height ]
            , shapes [ stroke Color.black ] [ createPath (List.head model.strokes  |> Maybe.withDefault [] )] ]
        ]



-- we have N lines to draw, but all we need to know is how to draw ONE line between two Points, then iterate

-- so we have our list of strokes, for each one of them, we'll create a SHAPE using shapes
-- 2: for each stroke, we split off the starting point, from all the others
-- the first point goes inside `path startingPoint`, the rest we accumulate in a list of `lineTo segments`


createPath : Stroke -> Shape
createPath stroke =
    let
        startingPoint =
            List.head (List.reverse stroke) |> Maybe.withDefault ( 0, 0 )

        -- assume this won't fail, if it does, it will be pretty obvious
        segments =
            List.tail (List.reverse stroke) |> Maybe.withDefault []
    in
    -- List Point -> List PathSegment
    -- lineTo : Point -> PathSegment
    path startingPoint (List.map lineTo segments)



-- line from (x1, y1) to (x2, y2)
-- Mouse.onDown -> lineWidth, (lineCap = "round"), lineTo, stroke
-- initialPoint = clientX / clientY
-- record the mouse positions between clicking and releasing
-- accumulate a list of those mouse positions and add those to another list of all the strokes
-- gives us undo/redo if we want
-- gives us the ability to completely separate event logic from data
-- hacks to cut down on size of list for very long-running drawings (save the pixel-buffer of the canvas and load it, for example, letting us delete the list but losing undo/redo for it)
---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }
