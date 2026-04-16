import SwiftUI

struct SessionTimelineView: View {
    let session: SessionRecord
    @State private var isCompact = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SessionSummaryCard(session: session)

                HStack {
                    Text("Timeline")
                        .font(CantoTypography.displaySmall)
                        .foregroundStyle(CantoColors.textPrimary)
                    Spacer()
                    Picker("View", selection: $isCompact) {
                        Text("Full").tag(false)
                        Text("Compact").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }

                ForEach(session.events) { event in
                    TimelineEventRow(event: event, isCompact: isCompact)
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(CantoColors.background)
    }
}
