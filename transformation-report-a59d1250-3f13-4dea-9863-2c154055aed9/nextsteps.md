# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version you intend to support.

## 2. Restore Dependencies

Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not fully support your target framework.

## 3. Build the Solution

Perform a full build to confirm no errors or warnings are introduced at compile time:

```bash
dotnet build --configuration Release
```

Address any warnings that may indicate compatibility concerns, particularly those related to platform-specific APIs.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failures may indicate behavioral differences between the legacy .NET Framework runtime and the current .NET runtime.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or review the code manually for any APIs that were available in .NET Framework but are absent or behave differently in cross-platform .NET. Common areas to check include:

- `System.Windows.Forms` or `System.Web` references (not available cross-platform)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions
- `AppDomain` usage
- Remoting or binary serialization

## 6. Run the Application on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to identify any runtime issues that do not surface during compilation:

```bash
dotnet run --configuration Release
```

## 7. Review NuGet Package Compatibility

Check that all referenced NuGet packages have versions compatible with your target framework. Visit [nuget.org](https://www.nuget.org) to verify package compatibility if any runtime errors occur related to missing types or methods.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the published output directory to confirm all required files are present.