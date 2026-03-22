# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework. Replace any packages flagged as incompatible with their supported equivalents.

## 3. Build the Solution

Perform a full build to confirm there are no compilation errors:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during the build, particularly those related to nullable reference types or obsolete API usage, as these can indicate areas that may cause runtime issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review the test results and investigate any failures. Failures at this stage often indicate behavioral differences between .NET Framework and cross-platform .NET, such as changes in:

- `System.Configuration` usage
- Windows-specific APIs (e.g., registry access, COM interop)
- File path handling differences between operating systems

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any remaining Windows-only API calls that may not behave correctly on Linux or macOS. You can enable this by ensuring the following is in your `.csproj`:

```xml
<PlatformNeutralAssembly>true</PlatformNeutralAssembly>
```

Alternatively, run the `dotnet-compatibility` tool or review analyzer warnings in your IDE.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that static analysis may not catch.

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime:

**Framework-dependent publish:**
```bash
dotnet publish -c Release -f net8.0
```

**Self-contained publish (example for Linux x64):**
```bash
dotnet publish -c Release -f net8.0 -r linux-x64 --self-contained true
```

Review the contents of the `publish` output folder to confirm all required assets and dependencies are present before deploying to the target environment.