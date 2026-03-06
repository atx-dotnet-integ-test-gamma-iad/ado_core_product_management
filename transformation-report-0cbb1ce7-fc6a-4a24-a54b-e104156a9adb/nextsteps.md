# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version you intend to support.

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not fully support the target framework. Consider updating or replacing any packages flagged with compatibility warnings.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings introduced at compile time:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to obsolete APIs or platform compatibility.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved after the migration:

```bash
dotnet test --configuration Release
```

Review the test results and investigate any failures to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or review the code manually for APIs that were available in .NET Framework but are not available or behave differently in cross-platform .NET. Common areas to check include:

- `System.Windows.Forms` or `System.Web` references (not available cross-platform)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (backslash separators)
- `AppDomain` usage
- Remoting or binary serialization

If any such APIs are found, replace them with cross-platform equivalents.

## 6. Validate Runtime Behavior on Target Platforms

Run the application on each platform you intend to support (Windows, Linux, macOS) and verify that the output and behavior are consistent:

```bash
dotnet run --configuration Release
```

Pay particular attention to file I/O, culture-sensitive formatting, and any interop code.

## 7. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent build for your target platform:

**Framework-dependent:**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory and confirm all required files are present before deploying to the target environment.