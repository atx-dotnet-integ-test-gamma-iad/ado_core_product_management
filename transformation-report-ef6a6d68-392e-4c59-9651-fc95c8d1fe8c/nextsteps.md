# Next Steps

The solution has no build errors following the transformation. Below are steps to validate, test, and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If it still references a Windows-only TFM such as `net472` or `net48`, update it accordingly.

## 2. Review NuGet Package Compatibility

Run the following command to check for any packages that may not fully support the target framework:

```bash
dotnet list package --outdated
```

Update any outdated or incompatible packages using:

```bash
dotnet add package <PackageName> --version <LatestVersion>
```

## 3. Restore and Build the Solution

Perform a clean restore and build to confirm there are no runtime or compile-time issues:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the build output for any warnings that may indicate compatibility concerns, even if they are not hard errors.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address the underlying logic or compatibility issues they surface.

## 5. Check for Windows-Specific API Usage

Even without build errors, the code may contain APIs that only function on Windows. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Look for `CA1416` warnings, which indicate platform-specific API calls that may fail on Linux or macOS.

## 6. Test on Target Platforms

Run the application on each platform you intend to support:

```bash
# On Linux or macOS
dotnet run --configuration Release
```

Verify that file paths, line endings, environment variables, and any external dependencies behave correctly on each platform.

## 7. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent build as appropriate:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained for a specific runtime
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before deployment.