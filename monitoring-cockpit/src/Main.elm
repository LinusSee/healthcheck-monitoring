module Main exposing (..)

import Browser
import Html exposing (text)



-- MAIN


main =
    Browser.element
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }


init : () -> ( RootModel, Cmd Msg )
init _ =
    ( { healthcheckData = [] }, Cmd.none )


type alias RootModel =
    { healthcheckData : List String }


type Msg
    = None


subscriptions : RootModel -> Sub Msg
subscriptions rootModel =
    Sub.none



-- UPDATE


update : Msg -> RootModel -> ( RootModel, Cmd Msg )
update _ rootModel =
    ( rootModel, Cmd.none )



-- VIEW


view : RootModel -> Html.Html Msg
view _ =
    text "Hello World!"
