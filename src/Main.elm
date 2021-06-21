module Main exposing (..)

-- import Html.Events.Extra.Touch as Touch

import Browser
import Canvas exposing (..)
import Canvas.Settings exposing (..)
import Canvas.Settings.Line exposing (..)
import Color exposing (Color)
import Html exposing (..)
import Html.Attributes exposing (..)
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
    { strokes : List Point
    , color : Color
    , shape : Maybe Renderable
    }


type alias Model =
    { actions : List Actions
    , color : Color
    , undo : List Actions
    , redo : List Actions

    -- Possible alternative design involves holding a buffer to the current stroke, and using "strokes" to hold all *previously* finished strokes.
    -- , currentStroke : Stroke
    , isDrawing : Bool
    }


init : ( Model, Cmd Msg )
init =
    ( { actions = []
      , undo = []
      , redo = []
      , isDrawing = False
      , color = Color.black
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
                , actions = { strokes = [ point ], color = model.color, shape = Nothing } :: model.actions
                , redo = []
            }

        CanvasMouseMove point ->
            let
                prevStroke =
                    List.head model.actions |> Maybe.withDefault { strokes = [ point ], color = model.color, shape = Nothing }

                currentStroke =
                    { prevStroke | strokes = point :: prevStroke.strokes }
            in
            if model.isDrawing then
                { model | actions = currentStroke :: (List.tail model.actions |> Maybe.withDefault model.actions) }

            else
                model

        CanvasMouseUp ->
            let
                updatedModel =
                    { model | isDrawing = False }
            in
            case List.head model.actions of
                Just stroke ->
                    { updatedModel | undo = stroke :: model.undo }

                Nothing ->
                    updatedModel

        ColorPicker color ->
            { model | color = color }

        ClearAll ->
            -- when the clear button is hit, we treat this as a new action that clears the redo stack and the list of strokes but preserves the current stroke color and the list of undoable actions (clear itself can be undone)
            { model
                | redo = []
                , actions = { strokes = [], color = model.color, shape = Just clearRect } :: model.actions
                , undo = { strokes = [], color = model.color, shape = Just clearRect } :: model.undo
            }

        Undo ->
            -- undo should take the most recent action off the undo stack (if it exists), set the current action to the new head of the undo list, and append the previous head of the undo stack to the redo stack
            -- when the undo stack is empty, the undo button should be disabled
            -- when the undo stack is empty AND the redo stack is empty, both the undo and the redo buttons should be disabled
            { model
                | undo = List.tail model.undo |> Maybe.withDefault model.undo
                , redo = List.take 1 model.undo ++ model.redo
                , actions = List.tail model.actions |> Maybe.withDefault model.actions
            }

        Redo ->
            -- redo should take the most recent action off the redo stack (if it exists),set the current action to the new head of the redo list, and append the previous head of the redo stack to the undo stack
            -- when the redo stack is empty, the redo button should be disabled
            -- current BUG: redo is one behind
            { model
                | undo = List.take 1 model.redo ++ model.undo
                , redo = List.tail model.redo |> Maybe.withDefault model.redo
                , actions = (List.head model.redo |> Maybe.map (\x -> x :: model.actions)) |> Maybe.withDefault model.actions
            }
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
             ]
                ++ List.map
                    (\strk ->
                        -- if strk.shapes has a value
                        if strk.shape /= Nothing then
                            clearRect

                        else
                            shapes
                                [ stroke strk.color, lineCap RoundCap, lineWidth 4, lineJoin RoundJoin ]
                                [ createPath strk ]
                    )
                    -- reversed so that the newest stroke is drawn at the top
                    (List.reverse model.actions)
            )
        , div [] (renderColorGrid colorList)
        , div [ class "controls-container" ]
            [ button
                [ class "buttons"
                , isButtonDisabled model.undo Undo
                ]
                (buttonLabel "undo")
            , button
                [ class "buttons"
                , isButtonDisabled model.redo Redo
                ]
                (buttonLabel "redo")
            , button
                [ class "buttons"
                , isButtonDisabled model.actions ClearAll
                ]
                (buttonLabel "clear")
            ]
        ]


isButtonDisabled : List Actions -> Msg -> Attribute Msg
isButtonDisabled model htmlMsg =
    if List.length model > 0 then
        Mouse.onClick (\_ -> htmlMsg)

    else
        disabled True


buttonLabel : String -> List (Html msg)
buttonLabel htmlTxt =
    [ Html.text htmlTxt ]


clearRect : Renderable
clearRect =
    shapes [ fill Color.white ] [ rect ( 0, 0 ) width height ]


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
            List.head (List.reverse stroke.strokes) |> Maybe.withDefault ( 0, 0 )

        segments =
            List.tail (List.reverse stroke.strokes) |> Maybe.withDefault []
    in
    path startingPoint (List.map (\segment -> lineTo segment) segments)



{-
   NEXT:
       * implement draw point
       * implement line size picker
       * get a drawing pen cursor working
    BUGS:
        * if you mouseup outside of the canvas, it doesn't trigger the CanvasMouseUp Msg
-}
