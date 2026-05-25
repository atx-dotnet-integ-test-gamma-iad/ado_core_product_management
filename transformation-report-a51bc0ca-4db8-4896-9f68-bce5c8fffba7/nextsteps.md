# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this matches the version of the .NET SDK you have installed. You can check your installed SDKs by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been resolved through compatibility shims.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to deprecated APIs or platform-specific calls that may not behave consistently across operating systems.

## 4. Run the Test Suite

If the solution contains a test project, execute all tests to verify runtime behavior is unchanged:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures at this stage may indicate behavioral differences between the legacy .NET Framework runtime and the new .NET runtime, even when the build succeeds.

## 5. Check for Windows-Specific API Usage

Even with a successful build, certain APIs may compile but fail at runtime on non-Windows platforms. Review the code for usage of the following:

- `Microsoft.Win32` registry APIs
- `System.Windows.Forms` or `System.Drawing` (GDI+)
- COM interop or P/Invoke calls targeting Windows-only libraries
- `AppDomain` members that are no longer supported

Use the [.NET Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to surface these issues:

```xml
<PackageReference Include="Microsoft.DotNet.Analyzers.Compatibility" Version="0.2.12-alpha" />
```

## 6. Validate Configuration and App Settings

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables as appropriate for .NET. Verify that `ConfigurationManager` usages have been replaced or that the `System.Configuration.ConfigurationManager` NuGet package has been added if backward compatibility is required.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to identify any runtime-only issues that static analysis would not catch.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. Review the publish output directory to confirm all required files are present before deploying.