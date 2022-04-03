module Main exposing (..)

import Browser
import Html exposing (div, text)
import Http
import Models.HealthcheckData as HealthcheckData



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
    ( { healthcheckData = []
      , httpStatus = Loading
      }
    , Http.get
        { url = "http://localhost:3000/mock-monitoring-backend/api/v1/healthchecks/355c722a-4f1c-42fb-a9a3-4fb11f5a0508/data"
        , expect = Http.expectJson GotTaskHealthcheckData HealthcheckData.healthcheckDataResponseDecoder
        }
    )


type alias RootModel =
    { healthcheckData : List HealthcheckData.HealthcheckRoot
    , httpStatus : HttpStatus
    }


type HttpStatus
    = Success
    | Loading
    | Error Http.Error


type Msg
    = GotTaskHealthcheckData (Result Http.Error (List HealthcheckData.HealthcheckRoot))


subscriptions : RootModel -> Sub Msg
subscriptions rootModel =
    Sub.none



-- UPDATE


update : Msg -> RootModel -> ( RootModel, Cmd Msg )
update (GotTaskHealthcheckData result) rootModel =
    case result of
        Ok healthcheckRoots ->
            ( { rootModel | healthcheckData = healthcheckRoots, httpStatus = Success }, Cmd.none )

        Err error ->
            ( { rootModel | httpStatus = Error error }, Cmd.none )



-- VIEW


view : RootModel -> Html.Html Msg
view rootModel =
    div [] [ text (Debug.toString rootModel) ]


healthcheckOutcomeAsString : HealthcheckData.HealthcheckOutcome -> String
healthcheckOutcomeAsString outcome =
    case outcome of
        HealthcheckData.UP ->
            "UP"

        HealthcheckData.DOWN ->
            "DOWN"

        HealthcheckData.UNKNOWN state ->
            "Unbekanntes Ergebnis: " ++ state


httpStatusAsString : HttpStatus -> String
httpStatusAsString status =
    case status of
        Success ->
            "Success"

        Loading ->
            "Loading"

        Error httpError ->
            "Error with message: " ++ Debug.toString httpError
