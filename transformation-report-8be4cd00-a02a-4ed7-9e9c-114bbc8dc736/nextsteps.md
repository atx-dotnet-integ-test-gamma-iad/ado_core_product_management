# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on all machines that will build or run this project.

## 2. Restore NuGet Packages

Run the following command from the solution root to ensure all dependencies are restored cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version mismatches.

## 3. Build the Solution

Perform a full build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify behavioral correctness after migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee that runtime behavior is unchanged from the original .NET Framework version.

## 5. Check for Windows-Specific API Usage

Use the .NET Compatibility Analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining Windows-specific API calls that may fail on Linux or macOS. You can also run:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Look for `CA1416` platform compatibility warnings in the output.

## 6. Run the Application on Target Platforms

Execute the application on each platform you intend to support (Windows, Linux, macOS) and verify expected behavior:

```bash
dotnet run --configuration Release
```

Pay particular attention to file path handling, registry access, and any COM interop or P/Invoke calls, as these are common sources of cross-platform issues.

## 7. Validate Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables as appropriate for .NET.

## 8. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your intended runtime identifier (RID) such as `win-x64` or `osx-x64`. Review the contents of the publish output directory before deploying to the target environment.