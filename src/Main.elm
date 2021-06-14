module Main exposing (..)

-- import Html.Events.Extra.Touch as Touch

import Browser
import Canvas exposing (..)
import Canvas.Settings exposing (..)
import Canvas.Settings.Line exposing (..)
import Color
import Debug exposing (log)
import Html exposing (Html, aside, div, h1, img, text)
import Html.Attributes exposing (src, style)
import Html.Events.Extra.Mouse as Mouse
import Html.Attributes exposing (class)

{-
   elm-canvas:
   * clear : Point -> Float -> Float -> Renderable
       ex: `[ clear (0, 0) width height ]
       use `clear` to remove the contents of a rectangle in the screen and make them transparent

   * Canvas.Settings.Line lineWidth : Float -> Setting
       specify the thickness of lines in space units

   * Canvas.Settings.Line lineCap : LineCap -> Setting
       determines how the end points of every line are drawn
       see [lineCap](https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/lineCap) for more usage details
-}


{-| `width` is a global variable representing the width of the canvas.
-}
width : number
width =
    700


{-| `height` is a global variable representing the height of the canvas.
-}
height : number
height =
    400



---- MODEL ----


{-| the `Point` type represents a single pair of ( x, y ) coordinates.
-}
type alias Point =
    ( Float, Float )


{-| the `Stroke` type represents a list of coordinate pairs of `.offsetPos` mouse positions from a user's `Mouse.onDown` until their `Mouse.onUp`.
-}
type alias Stroke =
    List Point


type alias Model =
    { -- `strokes` represents a list of all `Stroke`s; together they form the drawing.
      strokes : List Stroke

    -- Possible alternative design involves holding a buffer to the current stroke, and using "strokes" to hold all *previously* finished strokes.
    -- , currentStroke : Stroke
    , isDrawing : Bool
    }


init : ( Model, Cmd Msg )
init =
    ( { strokes = []
      , isDrawing = False
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = CanvasMouseDown Point
    | CanvasMouseMove Point
    | CanvasMouseUp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( case msg of
        CanvasMouseDown point ->
            { model
                | isDrawing = True
                , strokes = [ point ] :: model.strokes
            }

        CanvasMouseMove point ->
            let
                prevStroke =
                    List.head model.strokes |> Maybe.withDefault [ point ]

                currentStroke =
                    point :: prevStroke
            in
            if model.isDrawing then
                { model | strokes = currentStroke :: ( List.tail model.strokes |> Maybe.withDefault model.strokes ) }

            else
                model

        CanvasMouseUp ->
            { model | isDrawing = False }
    , Cmd.none
    )



---- VIEW ----


view : Model -> Html Msg
view model =
    div [ class "container"]
        [ Canvas.toHtml ( width, height )
            [ Mouse.onDown (.offsetPos >> CanvasMouseDown)
            , Mouse.onMove (.offsetPos >> CanvasMouseMove)
            , Mouse.onUp (\_ -> CanvasMouseUp)
            ]
            -- this first shape fills the canvas with white
            [ shapes [ fill Color.white ] [ rect ( 0, 0 ) width height ]
            -- this second shape dictates how each Mouse.onDown stroke is drawn
            , shapes [ stroke Color.black, lineCap RoundCap, lineWidth 2, lineJoin RoundJoin ] (List.map createPath model.strokes) ]
        ]



-- we have N lines to draw, but all we need to know is how to draw ONE line between two Points, then iterate
-- so we have our list of strokes, for each one of them, we'll create a SHAPE using shapes
-- 2: for each stroke, we split off the starting point, from all the others
-- the first point goes inside `path startingPoint`, the rest we accumulate in a list of `lineTo segments`


{-| createPath programmatically generates a path with a starting point and a list of segments, where the starting point is the first element in the model's strokes list, and the list of segments are comprised from the rest.
-}
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
    path startingPoint (List.map (\segment -> lineTo segment) segments)



--                  List.map(segments, segment => lineTo(segment))
-- line from (x1, y1) to (x2, y2)
-- Mouse.onDown -> lineWidth, (lineCap = "round"), lineTo, stroke
-- initialPoint = clientX / clientY
-- record the mouse positions between clicking and releasing
-- accumulate a list of those mouse positions and add those to another list of all the strokes
-- gives us undo/redo if we want
-- gives us the ability to completely separate event logic from data
-- hacks to cut down on size of list for very long-running drawings (save the pixel-buffer of the canvas and load it, for example, letting us delete the list but losing undo/redo for it)
-- NOTES:
-- with our current design, a single click doesn't color a single pixel
---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }
