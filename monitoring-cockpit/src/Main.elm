module Main exposing (..)

import Browser
import BusinessLogic.Healthcheck as BLHealthcheck
import Chart as Chart
import Chart.Attributes as ChartAttributes
import Dict exposing (Dict)
import Html exposing (button, div, p, text)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Models.HealthcheckData as HealthcheckData
import Result.Extra as ResultExtra
import Svg as Svg



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
    ( { healthchecks =
            [ { id = "355c722a-4f1c-42fb-a9a3-4fb11f5a0508"
              , name = "taskdata healthcheck"
              , url = "not yet important"
              , chartConfigs = [ { healthcheckName = "TaskQueue", fieldname = "itemCount" } ]
              }
            ]
      , selectedHealthcheckId = Nothing
      , healthcheckData = Dict.empty
      , processedHealthcheckData = Dict.empty
      , healthcheckErrors = Dict.singleton "355c722a-4f1c-42fb-a9a3-4fb11f5a0508" [ "Initial error" ]
      , httpStatus = Loading
      }
    , Cmd.batch (requestHealthcheckData [ { id = "355c722a-4f1c-42fb-a9a3-4fb11f5a0508", name = "taskdata healthcheck", url = "not yet important", chartConfigs = [ { healthcheckName = "TaskQueue", fieldname = "itemCount" }, { healthcheckName = "IncorrectTasks", fieldname = "noCurrentWorker" } ] } ])
    )


type alias RootModel =
    { healthchecks : List HealthcheckData.Healthcheck
    , selectedHealthcheckId : Maybe String
    , healthcheckData : Dict String (List HealthcheckData.HealthcheckRoot)
    , processedHealthcheckData : Dict String (Dict String (List ( Float, Float )))
    , healthcheckErrors : Dict String (List String)
    , httpStatus : HttpStatus
    }


type HttpStatus
    = Success
    | Loading
    | Error Http.Error


type Msg
    = GotTaskHealthcheckData HealthcheckData.Healthcheck (Result Http.Error (List HealthcheckData.HealthcheckRoot))
    | HealthcheckListItemSelected String


subscriptions : RootModel -> Sub Msg
subscriptions rootModel =
    Sub.none



-- UPDATE


update : Msg -> RootModel -> ( RootModel, Cmd Msg )
update msg rootModel =
    case msg of
        GotTaskHealthcheckData healthcheck result ->
            case result of
                Ok healthcheckRoots ->
                    let
                        -- maybeChecks =
                        --     List.map (\root -> List.head root.checks) healthcheckRoots
                        --
                        -- checks =
                        --     List.map (Maybe.withDefault { name = "default", state = HealthcheckData.UNKNOWN "defaultErr", data = [] }) maybeChecks
                        --
                        -- dataResult =
                        --     healthchecksToData "itemCount" checks
                        dataForConfig =
                            List.map (\config -> ( config, BLHealthcheck.extractValuesForRoots config healthcheckRoots )) healthcheck.chartConfigs

                        dataWithoutErrors =
                            List.filter (\( _, dataResult ) -> ResultExtra.isOk dataResult) dataForConfig
                                |> List.map (\( config, okResult ) -> ( config.healthcheckName, Result.withDefault [] okResult ))

                        mappedData =
                            List.map
                                (\( config, values ) ->
                                    ( config
                                    , List.indexedMap Tuple.pair values
                                        |> List.map (\( val1, val2 ) -> ( toFloat val1, val2 ))
                                    )
                                )
                                dataWithoutErrors

                        errors =
                            List.map (\( _, dataResult ) -> dataResult) dataForConfig
                                |> List.filter ResultExtra.isErr
                                |> List.map
                                    (\dataResult ->
                                        case dataResult of
                                            Ok _ ->
                                                "No error."

                                            Err error ->
                                                error
                                    )

                        -- healthcheckResult =
                        --     BLHealthcheck.extractValuesForRoots { healthcheckName = "TaskQueue", fieldname = "itemCount" } healthcheckRoots
                        -- floatData =
                        --     case healthcheckResult of
                        --         Ok data ->
                        --             List.indexedMap Tuple.pair data
                        --                 |> List.map (\( val1, val2 ) -> ( toFloat val1, val2 ))
                        --
                        --         Err error ->
                        --             []
                        -- nodeDataDict =
                        --     Dict.singleton "TaskQueue" floatData
                        nodeDataDict =
                            Dict.fromList mappedData

                        _ =
                            Debug.log "dataForConfig" (Debug.toString dataForConfig)

                        _ =
                            Debug.log "nodeDataDict" (Debug.toString nodeDataDict)

                        _ =
                            Debug.log "Values" (Debug.toString dataWithoutErrors)
                    in
                    ( { rootModel
                        | healthcheckData = Dict.insert healthcheck.id healthcheckRoots rootModel.healthcheckData
                        , httpStatus = Success
                        , processedHealthcheckData = Dict.insert healthcheck.id nodeDataDict rootModel.processedHealthcheckData
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( { rootModel | httpStatus = Error error }, Cmd.none )

        HealthcheckListItemSelected healthcheckId ->
            ( { rootModel | selectedHealthcheckId = Just healthcheckId }, Cmd.none )



-- VIEW


view : RootModel -> Html.Html Msg
view rootModel =
    div []
        [ viewHealthchecks rootModel.healthchecks
        , p [] [ text (Debug.toString rootModel.processedHealthcheckData) ]
        , case rootModel.selectedHealthcheckId of
            Just selectedId ->
                case Dict.get selectedId rootModel.processedHealthcheckData of
                    Just data ->
                        viewLineCharts data

                    -- viewLineChart data
                    Nothing ->
                        div [] [ text ("No data for key: " ++ selectedId) ]

            Nothing ->
                div [] [ text "No healthcheck selected yet" ]
        , case rootModel.selectedHealthcheckId of
            Just selectedId ->
                div []
                    (case Dict.get selectedId rootModel.healthcheckErrors of
                        Just errors ->
                            List.map text errors

                        Nothing ->
                            [ text "No error present" ]
                    )

            Nothing ->
                div [] []
        ]


viewHealthchecks : List HealthcheckData.Healthcheck -> Html.Html Msg
viewHealthchecks healthchecks =
    div []
        (List.map
            (\healthcheck -> viewHealthcheckListItem healthcheck)
            healthchecks
        )


viewHealthcheckListItem : HealthcheckData.Healthcheck -> Html.Html Msg
viewHealthcheckListItem healthcheck =
    div []
        [ button [ onClick (HealthcheckListItemSelected healthcheck.id) ] [ text healthcheck.name ]
        ]


viewLineCharts : Dict String (List ( Float, Float )) -> Html.Html Msg
viewLineCharts nodeDataDict =
    div [] (List.map viewLineChart (Dict.values nodeDataDict))


viewLineChart : List ( Float, Float ) -> Html.Html Msg
viewLineChart data =
    div [ class "healthcheck-chart" ]
        [ Chart.chart
            [ ChartAttributes.height 300
            , ChartAttributes.width 300
            ]
            [ Chart.xLabels []
            , Chart.yLabels [ ChartAttributes.withGrid ]
            , Chart.labelAt ChartAttributes.middle (ChartAttributes.percent 0) [ ChartAttributes.moveDown 40 ] [ Svg.text "TaskCount" ]
            , Chart.series Tuple.first
                [ Chart.interpolated Tuple.first [] []
                , Chart.interpolated Tuple.second [] []
                ]
                data
            ]
        ]



-- Logic


requestHealthcheckData : List HealthcheckData.Healthcheck -> List (Cmd Msg)
requestHealthcheckData healthchecks =
    List.map
        (\healthcheck ->
            Http.get
                { url = "http://localhost:3000/mock-monitoring-backend/api/v1/healthchecks/" ++ healthcheck.id ++ "/data"
                , expect = Http.expectJson (GotTaskHealthcheckData healthcheck) HealthcheckData.healthcheckDataResponseDecoder
                }
        )
        healthchecks


healthchecksToData : String -> List HealthcheckData.HealthcheckNode -> Result String (List ( Int, Int ))
healthchecksToData fieldname nodes =
    let
        healthcheckFieldResults =
            List.map (healthcheckToData fieldname) nodes

        correctHealthcheckFields =
            List.filter isNotError healthcheckFieldResults

        healthcheckFields =
            List.map (Result.withDefault { fieldname = "def", value = HealthcheckData.NumericField -1 }) correctHealthcheckFields
    in
    case List.any isError healthcheckFieldResults of
        True ->
            Err "Contained errors"

        False ->
            case List.all HealthcheckData.isNumericField healthcheckFields of
                True ->
                    Ok (List.indexedMap Tuple.pair (List.map HealthcheckData.extractNumeric healthcheckFields))

                False ->
                    Err "Not all numerics"


healthcheckToData : String -> HealthcheckData.HealthcheckNode -> Result String HealthcheckData.HealthcheckField
healthcheckToData fieldname node =
    let
        maybeHealthcheckField =
            List.head (List.filter (matchesFieldName fieldname) node.data)
    in
    case maybeHealthcheckField of
        Just field ->
            Ok field

        Nothing ->
            Err ("No field found matching name: " ++ fieldname)


isError : Result a b -> Bool
isError result =
    case result of
        Ok _ ->
            False

        Err _ ->
            True


isNotError : Result a b -> Bool
isNotError result =
    not (isError result)


matchesFieldName : String -> HealthcheckData.HealthcheckField -> Bool
matchesFieldName targetFieldname field =
    field.fieldname == targetFieldname


plotData =
    [ { age = 0, x = 40, y = 4 }
    , { age = 5, x = 80, y = 24 }
    , { age = 10, x = 120, y = 36 }
    , { age = 15, x = 180, y = 54 }
    , { age = 20, x = 184, y = 60 }
    ]


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
