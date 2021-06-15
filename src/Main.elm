module Main exposing (..)

-- import Html.Events.Extra.Touch as Touch

import Browser
import Canvas exposing (..)
import Canvas.Settings exposing (..)
import Canvas.Settings.Line exposing (..)
import Color exposing (Color)
import Html exposing (..)
import Html.Attributes exposing (class, src, style)
import Html.Events.Extra.Mouse as Mouse



{-
   elm-canvas:
   * clear : Point -> Float -> Float -> Renderable
       ex: `[ clear (0, 0) width height ]
       use `clear` to remove the contents of a rectangle in the screen and make them transparent
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


{-| `colorList` is a list of all Color.Color types.
-}
colorList : List (List Color)
colorList =
    [ [ Color.lightRed
      , Color.lightOrange
      , Color.lightYellow
      , Color.lightGreen
      , Color.lightBlue
      , Color.lightPurple
      , Color.lightBrown
      , Color.red
      , Color.orange
      , Color.yellow
      , Color.green
      , Color.blue
      , Color.purple
      , Color.brown
      , Color.darkRed
      , Color.darkOrange
      , Color.darkYellow
      , Color.darkGreen
      , Color.darkBlue
      , Color.darkPurple
      , Color.darkBrown
      , Color.white
      , Color.lightGrey
      , Color.grey
      , Color.darkGrey
      , Color.lightCharcoal
      , Color.charcoal
      , Color.darkCharcoal
      , Color.black
      ]
    ]



---- MODEL ----


{-| the `Point` type represents a single pair of ( x, y ) coordinates.
-}
type alias Point =
    ( Float, Float )


{-| the `Stroke` type represents a list of coordinate pairs of `.offsetPos` mouse positions from a user's `Mouse.onDown` until their `Mouse.onUp`.
-}
type alias Stroke =
    { data : List Point
    , color : Color
    }


type alias Model =
    { -- `strokes` represents a list of all `Stroke`s; together they form the drawing.
      strokes : List Stroke
    , color : Color

    -- Possible alternative design involves holding a buffer to the current stroke, and using "strokes" to hold all *previously* finished strokes.
    -- , currentStroke : Stroke
    , isDrawing : Bool
    }


init : ( Model, Cmd Msg )
init =
    ( { strokes = []
      , isDrawing = False
      , color = Color.black
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = CanvasMouseDown Point
    | CanvasMouseMove Point
    | CanvasMouseUp
    | ColorPicker Color



-- | ColorPicker Color


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( case msg of
        CanvasMouseDown point ->
            { model
                | isDrawing = True

                -- start creating a new stroke
                , strokes = { data = [ point ], color = model.color } :: model.strokes
            }

        CanvasMouseMove point ->
            let
                prevStroke =
                    List.head model.strokes |> Maybe.withDefault { data = [ point ], color = model.color }

                currentStroke =
                    { prevStroke | data = point :: prevStroke.data }
            in
            if model.isDrawing then
                { model | strokes = currentStroke :: (List.tail model.strokes |> Maybe.withDefault model.strokes) }

            else
                model

        CanvasMouseUp ->
            { model | isDrawing = False }

        ColorPicker color ->
            { model | color = color }
    , Cmd.none
    )



---- VIEW ----


view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ p [ class "title" ] []
        , Canvas.toHtml ( width, height )
            [ Mouse.onDown (.offsetPos >> CanvasMouseDown)
            , Mouse.onMove (.offsetPos >> CanvasMouseMove)
            , Mouse.onUp (\_ -> CanvasMouseUp)
            ]
            -- this first shape fills the canvas with white
            ([ shapes [ fill Color.white ] [ rect ( 0, 0 ) width height ]

             -- this second shape dictates how each Mouse.onDown line stroke is drawn
             -- , shapes [ stroke model.color, lineCap RoundCap, lineWidth 2, lineJoin RoundJoin ] (List.map createPath model.strokes)
             ]
                ++ List.map
                    (\strk ->
                        shapes
                            [ stroke strk.color, lineCap RoundCap, lineWidth 4, lineJoin RoundJoin ]
                            [ createPath strk ]
                    )
                    model.strokes
            )
        , div [] (renderColorGrid colorList)
        ]


colorGrid : List Color -> Html Msg
colorGrid colors =
    ul [ class "color-grid-container" ]
        (List.map
            (\color ->
                li
                    [ class "color-grid-elem"
                    ]
                    [ button
                        [ class "color-grid-button"
                        , style "background-color" (Color.toCssString color)
                        , Mouse.onClick (\_ -> ColorPicker color)
                        ]
                        []
                    ]
            )
            colors
        )


renderColorGrid : List (List Color) -> List (Html Msg)
renderColorGrid elem =
    List.map colorGrid elem


{-| createPath programmatically generates a path with a starting point and a list of segments, where the starting point is the first element in the model's strokes list, and the list of segments are comprised from the rest.
-}
createPath : Stroke -> Shape
createPath stroke =
    let
        startingPoint =
            List.head (List.reverse stroke.data) |> Maybe.withDefault ( 0, 0 )

        segments =
            List.tail (List.reverse stroke.data) |> Maybe.withDefault []
    in
    path startingPoint (List.map (\segment -> lineTo segment) segments)



{-
   NEXT:
       * implement undo/redo
       * implement clear all
       * implement draw point
       * implement color picker
       * implement line size picker
    BUGS:
        * if you mouseup outside of the canvas, it doesn't trigger the CanvasMouseUp Msg
-}
---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }
