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



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }


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
type alias Actions =
    { data : List Point
    , color : Color
    }


type alias Model =
    { -- `strokes` represents a list of all `Stroke`s; together they form the drawing.
      actions : List Actions
    , color : Color
    , prevState : List Actions

    -- Possible alternative design involves holding a buffer to the current stroke, and using "strokes" to hold all *previously* finished strokes.
    -- , currentStroke : Stroke
    , isDrawing : Bool
    }


init : ( Model, Cmd Msg )
init =
    ( { actions = []
      , isDrawing = False
      , color = Color.black
      , prevState = []
      }
    , Cmd.none
    )



{-
undo/redo/clear logic:
* once there is an action, it can be undone (undo button disabled -> enabled)
* once an action has been undone, it can be redone (redo button disabled -> enabled)
* a clear is an action added to the list of actions and can be undone or redone
* if there is a list of actions, undoing once adds that action to the list of re-doable actions
* when a new action is taken it is prepended to the list of actions, so the head is always the last action taken (FIFO queue)
* if you undo something and then take a NEW action (like drawing a new stroke), it empties the redo stack

-}
---- UPDATE ----


type Msg
    = CanvasMouseDown Point
    | CanvasMouseMove Point
    | CanvasMouseUp
    | ColorPicker Color
    | ClearAll
    | Undo
    | Redo


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( case msg of
        CanvasMouseDown point ->
            { model
                | isDrawing = True

                -- start creating a new stroke
                , actions = { data = [ point ], color = model.color } :: model.actions
            }

        CanvasMouseMove point ->
            let
                prevStroke =
                    List.head model.actions |> Maybe.withDefault { data = [ point ], color = model.color }

                currentStroke =
                    { prevStroke | data = point :: prevStroke.data }
            in
            if model.isDrawing then
                { model | actions = currentStroke :: (List.tail model.actions |> Maybe.withDefault model.actions) }

            else
                model

        CanvasMouseUp ->
            { model | isDrawing = False }

        ColorPicker color ->
            { model | color = color }

        ClearAll ->
            { model | actions = [], prevState = model.actions }

        Undo ->
            { model | actions = model.prevState }

        Redo ->
            model
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
             -- , shapes [ stroke model.color, lineCap RoundCap, lineWidth 2, lineJoin RoundJoin ] (List.map createPath model.actions)
             ]
                ++ List.map
                    (\strk ->
                        shapes
                            [ stroke strk.color, lineCap RoundCap, lineWidth 4, lineJoin RoundJoin ]
                            [ createPath strk ]
                    )
                    -- reversed so that the newest stroke is drawn at the top
                    (List.reverse model.actions)
            )
        , div [] (renderColorGrid colorList)
        , div [ class "controls-container" ]
            [ button [ class "buttons", Mouse.onClick (\_ -> Undo) ] [ Html.text "undo" ]
            , button [ class "buttons", Mouse.onClick (\_ -> Redo) ] [ Html.text "redo" ]
            , button [ class "buttons", Mouse.onClick (\_ -> ClearAll) ] [ Html.text "clear" ]
            ]
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
createPath : Actions -> Shape
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
       * implement line size picker
       * get a drawing pen cursor working
    BUGS:
        * if you mouseup outside of the canvas, it doesn't trigger the CanvasMouseUp Msg
-}
