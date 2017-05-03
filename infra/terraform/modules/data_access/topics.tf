# See: https://developer.github.com/webhooks/#events

# Topic for GH membership events
#
# See: https://developer.github.com/v3/activity/events/types/#membershipevent
resource "aws_sns_topic" "gh_membership_events" {
  name = "${var.env}_gh_membership_events"
}

# Topic for GH team events
#
# See: https://developer.github.com/v3/activity/events/types/#teamevent
resource "aws_sns_topic" "gh_team_events" {
  name = "${var.env}_gh_team_events"
}
