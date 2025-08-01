import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // Banner 图片
                    Image("banner")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    // 欢迎文本
                    VStack(alignment: .leading, spacing: 15) {
                        Text(NSLocalizedString("Hi Friend", comment: "Welcome text in help view"))
                            .font(.title2)
                            .bold()
                        
                        Text(NSLocalizedString("App Introduction", comment: "App introduction in help view"))
                            .font(.body)
                    }
                    .padding(.horizontal)
                    
                    // 使用说明
                    VStack(alignment: .leading, spacing: 20) {
                        Text(NSLocalizedString("Simple to Use", comment: "Usage instruction title"))
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            // 步骤1
                            HStack(alignment: .top, spacing: 12) {
                                Text("1")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Circle().fill(.gray))
                                
                                Text(NSLocalizedString("Step 1", comment: "First step in usage instructions"))
                                    .font(.body)
                            }
                            
                            // 步骤2
                            HStack(alignment: .top, spacing: 12) {
                                Text("2")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Circle().fill(.gray))
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(NSLocalizedString("Step 2 Text", comment: "Second step in usage instructions"))
                                    Image("trigger")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 60)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                            
                            // 步骤3
                            HStack(alignment: .top, spacing: 12) {
                                Text("3")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Circle().fill(.gray))
                                
                                Text(NSLocalizedString("Step 3", comment: "Third step in usage instructions"))
                                    .font(.body)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // 补充说明和结束语
                    VStack(alignment: .leading, spacing: 15) {
                        Text(NSLocalizedString("Additional Settings", comment: "Additional settings note"))
                            .font(.body)
                        
                        Text(NSLocalizedString("Good Luck", comment: "Final encouragement message"))
                            .font(.headline)
                            .padding(.top, 5)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle")
                            .foregroundStyle(.gray)
                            .font(.title2)
                    }
                }
            }
        }
    }
}