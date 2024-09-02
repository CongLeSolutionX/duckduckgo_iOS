//
//  UnifiedFeedbackRootView.swift
//  DuckDuckGo
//
//  Copyright © 2024 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import SwiftUI
import NetworkProtection

struct UnifiedFeedbackRootView: View {
    @StateObject var viewModel: UnifiedFeedbackFormViewModel

    var body: some View {
        UnifiedFeedbackCategoryView(UserText.pproFeedbackFormTitle, sources: UnifiedFeedbackReportType.self, selection: $viewModel.selectedReportType) {
            if let selectedReportType = viewModel.selectedReportType {
                switch UnifiedFeedbackReportType(rawValue: selectedReportType) {
                case nil:
                    EmptyView()
                case .general:
                    CompactIssueDescriptionFormView(viewModel: viewModel,
                                                    navigationTitle: UserText.pproFeedbackFormGeneralFeedbackTitle,
                                                    label: UserText.pproFeedbackFormGeneralFeedbackTitle,
                                                    placeholder: UserText.pproFeedbackFormGeneralFeedbackPlaceholder)
                case .requestFeature:
                    CompactIssueDescriptionFormView(viewModel: viewModel,
                                                    navigationTitle: UserText.pproFeedbackFormRequestFeatureTitle,
                                                    label: UserText.pproFeedbackFormRequestFeatureTitle,
                                                    placeholder: UserText.pproFeedbackFormRequestFeaturePlaceholder)
                case .reportIssue:
                    reportProblemView()
                }
            }
        }
        .onFirstAppear {
            Task {
                await viewModel.process(action: .reportActions)
            }
        }
    }

    @ViewBuilder
    func reportProblemView() -> some View {
        UnifiedFeedbackCategoryView(UserText.pproFeedbackFormReportProblemTitle,
                                    sources: UnifiedFeedbackCategory.self,
                                    selection: $viewModel.selectedCategory) {
            Group {
                if let selectedCategory = viewModel.selectedCategory {
                    switch UnifiedFeedbackCategory(rawValue: selectedCategory) {
                    case nil:
                        EmptyView()
                    case .subscription:
                        UnifiedFeedbackCategoryView(UserText.pproFeedbackFormReportPProProblemTitle,
                                                    sources: PrivacyProFeedbackSubcategory.self,
                                                    selection: $viewModel.selectedSubcategory) {
                            IssueDescriptionFormView(viewModel: viewModel,
                                                     placeholder: UserText.pproFeedbackFormReportProblemPlaceholder)
                        }
                    case .vpn:
                        UnifiedFeedbackCategoryView(UserText.pproFeedbackFormReportVPNProblemTitle,
                                                    sources: VPNFeedbackSubcategory.self,
                                                    selection: $viewModel.selectedSubcategory) {
                            IssueDescriptionFormView(viewModel: viewModel,
                                                     placeholder: UserText.pproFeedbackFormReportProblemPlaceholder)
                        }
                    case .pir:
                        UnifiedFeedbackCategoryView(UserText.pproFeedbackFormReportPIRProblemTitle,
                                                    sources: PIRFeedbackSubcategory.self,
                                                    selection: $viewModel.selectedSubcategory) {
                            IssueDescriptionFormView(viewModel: viewModel,
                                                     placeholder: UserText.pproFeedbackFormReportProblemPlaceholder)
                        }
                    case .itr:
                        UnifiedFeedbackCategoryView(UserText.pproFeedbackFormReportITRProblemTitle,
                                                    sources: ITRFeedbackSubcategory.self,
                                                    selection: $viewModel.selectedSubcategory) {
                            IssueDescriptionFormView(viewModel: viewModel,
                                                     placeholder: UserText.pproFeedbackFormReportProblemPlaceholder)
                        }
                    }
                }
            }
            .onFirstAppear {
                Task {
                    await viewModel.process(action: .reportSubcategory)
                }
            }
        }
        .onFirstAppear {
            Task {
                await viewModel.process(action: .reportCategory)
            }
        }
    }
}

struct UnifiedFeedbackCategoryView<Category: FeedbackCategoryProviding, Destination: View>: View where Category.AllCases == [Category], Category.RawValue == String {
    let title: String
    let prompt: String
    let sources: Category.Type
    let selection: Binding<String?>
    let destination: () -> Destination

    init(_ title: String,
         prompt: String = UserText.pproFeedbackFormSelectCategoryTitle,
         sources: Category.Type,
         selection: Binding<String?>,
         @ViewBuilder destination: @escaping () -> Destination) {
        self.title = title
        self.prompt = prompt
        self.sources = sources
        self.selection = selection
        self.destination = destination
    }

    var body: some View {
        VStack {
            List(selection: selection) {
                Section {
                    ForEach(sources.allCases) { option in
                        NavigationLink {
                            destination()
                        } label: {
                            Text(option.displayName)
                                .daxBodyRegular()
                                .foregroundColor(.init(designSystemColor: .textPrimary))
                        }
                        .tag(option.rawValue)
                        .listRowBackground(Color(designSystemColor: .surface))
                    }
                } header: {
                    Text(prompt)
                }
            }
            .listRowBackground(Color(designSystemColor: .surface))
        }
        .applyInsetGroupedListStyle()
        .navigationTitle(title)
    }
}

private struct CompactIssueDescriptionFormView: View {
    @ObservedObject var viewModel: UnifiedFeedbackFormViewModel
    @FocusState private var isTextEditorFocused: Bool

    let navigationTitle: String
    let label: String
    let placeholder: String

    var body: some View {
        configuredForm()
            .applyBackground()
            .navigationTitle(navigationTitle)
            .onFirstAppear {
                Task {
                    await viewModel.process(action: .reportSubmitShow)
                }
            }
    }

    @ViewBuilder
    private func form() -> some View {
        ScrollView {
            ScrollViewReader { scrollView in
                VStack {
                    VStack(alignment: .leading, spacing: 10) {
                        IssueDescriptionTextEditor(label: label,
                                                   placeholder: placeholder,
                                                   text: $viewModel.feedbackFormText,
                                                   focusState: $isTextEditorFocused,
                                                   scrollViewProxy: scrollView)
                    }
                    .foregroundColor(.secondary)
                    .background(Color(designSystemColor: .background))
                    .padding(16)
                    .daxFootnoteRegular()
                    submitButton()
                        .disabled(!viewModel.submitButtonEnabled)
                }
            }
        }
    }

    @ViewBuilder
    private func configuredForm() -> some View {
        if #available(iOS 16, *) {
            form().scrollDismissesKeyboard(.interactively)
        } else {
            form()
        }
    }

    @ViewBuilder
    private func submitButton() -> some View {
        Button {
            Task {
                _ = await viewModel.process(action: .submit)
            }
        } label: {
            Text(UserText.vpnFeedbackFormButtonSubmit)
        }
        .buttonStyle(UnifiedFeedbackFormButtonStyle())
        .padding(16)
    }
}

private struct IssueDescriptionFormView: View {
    @ObservedObject var viewModel: UnifiedFeedbackFormViewModel
    @FocusState private var isTextEditorFocused: Bool

    let placeholder: String

    var body: some View {
        configuredForm()
            .applyBackground()
            .navigationTitle(UserText.pproFeedbackFormReportProblemTitle)
            .onFirstAppear {
                Task {
                    await viewModel.process(action: .reportSubmitShow)
                }
            }
    }

    @ViewBuilder
    private func form() -> some View {
        ScrollView {
            ScrollViewReader { scrollView in
                VStack {
                    VStack(alignment: .leading, spacing: 10) {
                        header()
                            .padding(.horizontal, 4)
                        IssueDescriptionTextEditor(label: UserText.pproFeedbackFormTextBoxTitle,
                                                   placeholder: placeholder,
                                                   text: $viewModel.feedbackFormText,
                                                   focusState: $isTextEditorFocused,
                                                   scrollViewProxy: scrollView)
                        footer()
                            .padding(.horizontal, 4)
                    }
                    .foregroundColor(.secondary)
                    .background(Color(designSystemColor: .background))
                    .padding(16)
                    .daxFootnoteRegular()
                    submitButton()
                        .disabled(!viewModel.submitButtonEnabled)
                }
            }
        }
    }

    @ViewBuilder
    private func configuredForm() -> some View {
        if #available(iOS 16, *) {
            form().scrollDismissesKeyboard(.interactively)
        } else {
            form()
        }
    }

    @ViewBuilder
    private func header() -> some View {
        Text(LocalizedStringKey(UserText.pproFeedbackFormText1))
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.openURL, OpenURLAction { _ in
                Task {
                    await viewModel.process(action: .reportFAQClick)
                    await viewModel.process(action: .faqClick)
                }
                return .handled
            })

        Spacer()
            .frame(height: 1)
            .id(1)
    }

    @ViewBuilder
    private func footer() -> some View {
        Text(UserText.pproFeedbackFormText2)
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)

        VStack(alignment: .leading) {
            Text(UserText.pproFeedbackFormText3)
            Text(UserText.pproFeedbackFormText4)
        }

        Text(UserText.pproFeedbackFormText5)
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func submitButton() -> some View {
        Button {
            Task {
                _ = await viewModel.process(action: .submit)
            }
        } label: {
            Text(UserText.vpnFeedbackFormButtonSubmit)
        }
        .buttonStyle(UnifiedFeedbackFormButtonStyle())
        .padding(16)
    }
}

private struct IssueDescriptionTextEditor: View {
    let label: String
    let placeholder: String
    let text: Binding<String>
    let focusState: FocusState<Bool>.Binding
    let scrollViewProxy: ScrollViewProxy

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .textCase(.uppercase)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            TextEditorWithPlaceholder(text: text, placeholder: placeholder)
                .font(.body)
                .foregroundColor(.primary)
                .background(Color(designSystemColor: .panel))
                .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
                .frame(height: 100)
                .fixedSize(horizontal: false, vertical: true)
                .onChange(of: text.wrappedValue) { value in
                    text.wrappedValue = String(value.prefix(1000))
                }
        }
        .focused(focusState)
        .onChange(of: focusState.wrappedValue) { isFocused in
            guard isFocused else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    scrollViewProxy.scrollTo(1, anchor: .top)
                }
            }
        }
    }
}

private struct UnifiedFeedbackFormButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            .frame(height: 50)
            .background(Color(designSystemColor: .accent))
            .cornerRadius(8)
            .daxButton()
            .opacity(isEnabled ? 1.0 : 0.4)

    }

}

private struct TextEditorWithPlaceholder: View {
    let text: Binding<String>
    let placeholder: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: text)
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .foregroundColor(.secondary)
                    .opacity(0.5)
                    .padding(.top, 8)
                    .padding(.leading, 5)
            }
        }
    }
}

extension NSNotification.Name {
    static let unifiedFeedbackNotification: NSNotification.Name = Notification.Name(rawValue: "com.duckduckgo.notification.unifiedFeedback")
}