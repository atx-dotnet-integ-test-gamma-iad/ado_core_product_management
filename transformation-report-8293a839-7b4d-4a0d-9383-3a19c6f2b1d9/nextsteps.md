# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this matches the .NET SDK version installed on your machine by running:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any dependency conflicts or packages that could not be resolved.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to obsolete APIs or platform compatibility analyzers (e.g., `CA1416`).

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review test output carefully, paying attention to any tests that were previously passing under .NET Framework but now fail under the new runtime.

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the built-in platform compatibility warnings to identify any remaining usages of Windows-only APIs if cross-platform support is a requirement:

```bash
dotnet build /p:EnableNETAnalyzers=true
```

Look for diagnostics prefixed with `CA1416` which indicate platform-specific API calls.

## 6. Validate Runtime Behavior

Run the application directly and exercise its primary workflows:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Compare the output and behavior against the original .NET Framework version to confirm functional parity.

## 7. Review NuGet Package Versions

Check that all NuGet packages referenced in `AdoCore.csproj` have versions that support your target framework. Packages that previously targeted `net45` or similar may have newer versions with cross-platform support. You can audit this with:

```bash
dotnet list package --outdated
```

Update packages where newer, compatible versions are available.

## 8. Publish the Application

Once validation is complete, publish the application for your target platform:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value for your deployment target, for example `win-x64`, `linux-x64`, or `osx-x64`. Review the contents of the `publish` output directory before deploying to your target environment.