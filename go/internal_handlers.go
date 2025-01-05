package main

import (
	"fmt"
	"log/slog"
	"net/http"
	"sort"
	"time"
)

var chairsx_sql = `
WITH
active_rides AS (
  SELECT ride_id, COUNT(chair_sent_at) chair_sent_count FROM ride_statuses GROUP BY ride_id HAVING chair_sent_count < 6
),
active_chairs AS (
  SELECT chair_id FROM rides WHERE chair_id IS NOT NULL AND id IN (SELECT ride_id FROM active_rides)
)
SELECT chairs.id, chairs_ex.latitude, chairs_ex.longitude,
  model, speed
FROM chairs
  LEFT JOIN chairs_ex ON chairs_ex.id = chairs.id
  LEFT JOIN chair_models ON chair_models.name = model
WHERE is_active = true
  AND chairs.id NOT IN (SELECT chair_id FROM active_chairs)
`

type Chairx struct {
	ID        string  `db:"id"`
	Latitude  *int    `db:"latitude"`
	Longitude *int    `db:"longitude"`
	Model     string  `db:"model"`
	Speed     int     `db:"speed"`
	Status    *string `db:"status"`
}

type MatchItem struct {
	Priority       int
	RideID         string
	RideArea       int
	ChairID        string
	ChairArea      int
	WaitTime       int
	PickupDistance int
	DriveDistance  int
	Speed          int
}

const AreaThreshold = 200

// このAPIをインスタンス内から一定間隔で叩かせることで、椅子とライドをマッチングさせる
func internalGetMatching(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	rides := &[]Ride{}
	if err := db.SelectContext(ctx, rides, `SELECT * FROM rides WHERE chair_id IS NULL`); err != nil {
		writeError(w, http.StatusInternalServerError, err)
		return
	}

	if len(*rides) == 0 {
		w.WriteHeader(http.StatusNoContent)
		return
	}

	chairsx := &[]Chairx{}
	if err := db.SelectContext(ctx, chairsx, chairsx_sql); err != nil {
		writeError(w, http.StatusInternalServerError, err)
		return
	}

	if len(*chairsx) == 0 {
		w.WriteHeader(http.StatusNoContent)
		return
	}

	timeLimit := time.Now().Add(-15 * time.Second)
	var matchItems = make([]MatchItem, 0)
	for _, chair := range *chairsx {
		if chair.Latitude == nil || chair.Longitude == nil {
			continue
		}
		chairArea := *chair.Latitude < AreaThreshold
		for _, ride := range *rides {
			rideArea := ride.PickupLatitude < AreaThreshold
			if rideArea != chairArea && ride.CreatedAt.After(timeLimit) {
				continue
			}
			driveDistance := abs(ride.PickupLatitude-ride.DestinationLatitude) + abs(ride.PickupLongitude-ride.DestinationLongitude)
			pickupDistance := abs(ride.PickupLatitude-*chair.Latitude) + abs(ride.PickupLongitude-*chair.Longitude)
			speed := chair.Speed
			matchItems = append(matchItems, MatchItem{
				RideID:         ride.ID,
				ChairID:        chair.ID,
				PickupDistance: pickupDistance,
				DriveDistance:  driveDistance,
				Speed:          speed,
				Priority:       (pickupDistance + driveDistance) / speed,
			})
		}
	}

	sort.Slice(matchItems, func(i, j int) bool {
		return matchItems[i].Priority < matchItems[j].Priority
	})

	matchedRideIDs := make(map[string]bool)
	matchedChairIDs := make(map[string]bool)
	for _, matchItem := range matchItems {
		if matchedRideIDs[matchItem.RideID] || matchedChairIDs[matchItem.ChairID] {
			continue
		}
		matchedRideIDs[matchItem.RideID] = true
		matchedChairIDs[matchItem.ChairID] = true
		slog.Info(fmt.Sprintf("Matching ride %s with chair %s / Prio %d", matchItem.RideID, matchItem.ChairID, matchItem.Priority))
		if _, err := db.ExecContext(ctx, "UPDATE rides SET chair_id = ? WHERE id = ?", matchItem.ChairID, matchItem.RideID); err != nil {
			writeError(w, http.StatusInternalServerError, err)
			return
		}
		signalCondByID(matchItem.ChairID)

	}

	w.WriteHeader(http.StatusNoContent)
}
