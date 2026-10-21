import SwiftUI

/// Trailing inspector: details of the selection and the live controls for it.
struct InspectorPane: View {
    @Bindable var controller: PlayerController

    var body: some View {
        Form {
            SelectionSection(controller: controller)
            if controller.currentStateMachine != nil {
                InputsSection(controller: controller)
            }
            DataBindingSection(controller: controller)
            TextRunsSection(controller: controller)
            EventsSection(controller: controller)
        }
        .formStyle(.grouped)
    }
}
