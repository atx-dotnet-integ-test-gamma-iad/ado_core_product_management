# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm:

```bash
dotnet --version
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts. If any packages targeting `net45` or other legacy frameworks appear, consider finding their cross-platform equivalents on [NuGet](https://www.nuget.org).

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the build output for any warnings, particularly those related to nullable reference types, obsolete APIs, or platform compatibility (e.g., `CA1416` platform compatibility warnings).

## 4. Address Platform Compatibility Warnings

If the project previously used Windows-specific APIs (e.g., `System.Windows.Forms`, `Microsoft.Win32`, or COM interop), check the build output for `CA1416` warnings. These indicate APIs that may not function on non-Windows platforms. Annotate or guard such calls appropriately:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific code
}
```

## 5. Run Existing Tests

If the solution contains test projects, execute them to verify behavioral correctness after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully. Failures may indicate runtime behavioral differences between .NET Framework and modern .NET, particularly around:

- `AppDomain` usage
- Reflection behavior
- `System.Configuration` (replaced by `Microsoft.Extensions.Configuration`)
- Binary serialization (`BinaryFormatter` is disabled by default in .NET 5+)

## 6. Check for Removed or Replaced APIs

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for usage of APIs that were removed in modern .NET:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution-file>.sln
```

Pay particular attention to:

- `BinaryFormatter` — removed by default; migrate to `System.Text.Json` or `System.Xml.Serialization`
- `System.Web` — not available outside of ASP.NET Core
- `ConfigurationManager` — requires the `System.Configuration.ConfigurationManager` NuGet package

## 7. Manual Functional Testing

Run the application manually and exercise its primary workflows. Compare behavior against the legacy .NET Framework version to identify any regressions.

## 8. Validate on Target Platforms

If cross-platform support is a goal, test the application explicitly on each intended platform:

```bash
# On Linux or macOS
dotnet run --configuration Release
```

Confirm file paths, line endings, and any OS-specific behavior function as expected.

## 9. Publish the Application

Once validation is complete, publish the application for the target platform:

```bash
# Framework-dependent publish
dotnet publish -c Release -o ./publish

# Self-contained publish for a specific runtime
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Review the contents of the `./publish` directory to confirm all required assets are present before deploying to the target environment.